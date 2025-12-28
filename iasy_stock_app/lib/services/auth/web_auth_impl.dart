import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../config/auth_config.dart';
import '../../models/auth/auth_user_model.dart';
import 'web_storage_service_stub.dart'
    if (dart.library.html) 'web_storage_service_impl.dart';

/// Implementación real de autenticación web para Flutter web
class WebAuthImpl {
  static final Logger _logger = Logger();

  /// Inicia el flujo de autenticación web
  static Future<AuthUser?> signIn() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebAuthImpl solo está disponible en web');
    }

    try {
      _logger.i('🌐 Iniciando autenticación web...');

      // Generar parámetros PKCE
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      // Guardar parámetros para el callback
      await WebStorageService.setItem('auth_code_verifier', codeVerifier);
      await WebStorageService.setItem('auth_state', state);

      // Construir URL de autorización
      final authUrl = _buildAuthUrl(codeChallenge, state);

      _logger.i('🔗 URL de autorización: $authUrl');
      _logger.i('🔑 Code verifier guardado para callback');

      // Redirigir a Keycloak
      html.window.location.href = authUrl;

      // No retornamos nada aquí porque la página se redirige
      return null;
    } catch (e) {
      _logger.e('❌ Error en autenticación web: $e');
      return null;
    }
  }

  /// Procesa el callback de autenticación web
  static Future<AuthUser?> processCallback() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebAuthImpl solo está disponible en web');
    }

    try {
      _logger.i('🔐 Procesando callback de autenticación web...');

      final uri = Uri.parse(html.window.location.href);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final state = uri.queryParameters['state'];

      if (error != null) {
        _logger.e('❌ Error en callback: $error');
        return null;
      }

      if (code == null) {
        _logger.w('⚠️ No hay código de autorización en la URL');
        return null;
      }

      // Verificar estado
      final savedState = await WebStorageService.getItem('auth_state');
      if (state != savedState) {
        _logger.e('❌ Estado no coincide');
        return null;
      }

      _logger
          .i('✅ Código de autorización recibido: ${code.substring(0, 8)}...');

      // Obtener code verifier guardado
      final codeVerifier =
          await WebStorageService.getItem('auth_code_verifier');
      if (codeVerifier == null) {
        _logger.e('❌ Code verifier no encontrado');
        return null;
      }

      // Intercambiar código por tokens
      final tokens = await _exchangeCodeForTokens(code, codeVerifier);

      if (tokens != null) {
        _logger.i('🎉 Tokens obtenidos exitosamente');

        // Limpiar parámetros temporales
        await WebStorageService.removeItem('auth_code_verifier');
        await WebStorageService.removeItem('auth_state');

        // Decodificar ID token para obtener información del usuario
        final userInfo = _decodeIdToken(tokens['id_token'] ?? '');
        if (userInfo == null) {
          _logger.e('❌ Error al decodificar ID token');
          return null;
        }

        _logger.i('👤 Información del usuario decodificada:');
        _logger.i('   - ID: ${userInfo['sub']}');
        _logger.i(
            '   - Username: ${userInfo['preferred_username'] ?? userInfo['email']}');
        _logger.i('   - Email: ${userInfo['email']}');

        // Crear objeto AuthUser
        final authUser = AuthUser(
          id: userInfo['sub'] ?? '',
          username: userInfo['preferred_username'] ?? userInfo['email'] ?? '',
          email: userInfo['email'] ?? '',
          firstName: userInfo['given_name'] ?? '',
          lastName: userInfo['family_name'] ?? '',
          roles: _extractRoles(userInfo),
          accessToken: tokens['access_token'] ?? '',
          refreshToken: tokens['refresh_token'] ?? '',
          tokenExpiry: DateTime.now().add(Duration(
              seconds: tokens['expires_in'] ??
                  AuthConfig.accessTokenExpiryHours * 3600)),
          idToken: tokens['id_token'] ?? '',
        );

        // Guardar usuario y tokens
        await _saveUser(authUser);
        await _saveTokens(AuthTokens(
          accessToken: tokens['access_token'] ?? '',
          refreshToken: tokens['refresh_token'] ?? '',
          idToken: tokens['id_token'] ?? '',
          accessTokenExpiry: DateTime.now()
              .add(Duration(seconds: tokens['expires_in'] ?? 3600)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 30)),
        ));

        _logger.i('Usuario autenticado: ${authUser.username}');
        _logger.i('🎉 Autenticación web completada exitosamente');

        // Limpiar URL del navegador
        _cleanUrl();

        return authUser;
      } else {
        _logger.e('❌ Error al obtener tokens');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error al procesar callback web: $e');
      return null;
    }
  }

  /// Obtiene el usuario actual desde localStorage
  static Future<AuthUser?> getCurrentUser() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebAuthImpl solo está disponible en web');
    }

    try {
      final userJson =
          await WebStorageService.getJson(AuthConfig.userStorageKey);

      if (userJson == null) {
        return null;
      }

      final user = AuthUser.fromJson(userJson);

      // Verificar si el token aún es válido
      if (user.tokenExpiry.isBefore(DateTime.now())) {
        _logger.i('Token expirado, intentando renovar');
        final refreshedUser = await _refreshToken(user);
        return refreshedUser;
      }

      return user;
    } catch (e) {
      _logger.e('Error al obtener usuario actual: $e');
      return null;
    }
  }

  /// Cierra la sesión del usuario
  static Future<void> signOut() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebAuthImpl solo está disponible en web');
    }

    try {
      _logger.i('🚪 Cerrando sesión...');

      // Limpiar datos locales PRIMERO
      _logger.i('🧹 Iniciando limpieza de datos locales...');
      await _clearUserData();
      _logger.i('🧹 Datos locales limpiados');

      // Obtener refresh token para cerrar sesión en Keycloak (si aún existe)
      final tokensJson =
          await WebStorageService.getJson(AuthConfig.tokensStorageKey);
      if (tokensJson != null) {
        final tokens = AuthTokens.fromJson(tokensJson);
        if (tokens.refreshToken.isNotEmpty) {
          await _logoutFromKeycloak(tokens.refreshToken);
        }
      }

      // Redirigir a logout de Keycloak
      final logoutUrl =
          '${AuthConfig.keycloakIssuer}/protocol/openid-connect/logout?client_id=${AuthConfig.clientId}&post_logout_redirect_uri=${Uri.encodeComponent(AuthConfig.webLogoutUrl)}';
      _logger.i('🔗 Redirigiendo a logout de Keycloak');
      html.window.location.href = logoutUrl;

      _logger.i('✅ Sesión cerrada exitosamente');
    } catch (e) {
      _logger.e('❌ Error al cerrar sesión: $e');
      // Aún así, limpiar datos locales y redirigir
      await _clearUserData();
      html.window.location.href = '/login';
    }
  }

  /// Verifica si el usuario existe en el backend
  static Future<bool> checkUserExists(String keycloakId) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebAuthImpl solo está disponible en web');
    }

    try {
      final tokensJson =
          await WebStorageService.getJson(AuthConfig.tokensStorageKey);
      if (tokensJson == null) {
        _logger.w('❌ No se encontraron tokens para verificar usuario');
        return false;
      }

      final tokens = AuthTokens.fromJson(tokensJson);
      _logger.i('🔍 Verificando usuario en backend...');
      _logger
          .i('📋 Token de acceso: ${tokens.accessToken.substring(0, 20)}...');
      _logger.i('🌐 URL del backend: ${AuthConfig.apiBaseUrl}/api/v1/auth/me');

      // Llamar al endpoint /me que crea el usuario automáticamente si no existe
      final response = await http.get(
        Uri.parse('${AuthConfig.apiBaseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      _logger.i('📡 Respuesta del backend: ${response.statusCode}');
      if (response.statusCode != 200) {
        _logger.w(
            '❌ Error al verificar usuario en backend: ${response.statusCode}');
        _logger.w('📄 Cuerpo de respuesta: ${response.body}');
      }

      if (response.statusCode == 200) {
        _logger.i('✅ Usuario verificado/creado en el backend');
        return true;
      } else {
        _logger.w(
            '❌ Error al verificar usuario en backend: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error al verificar existencia del usuario', error: e);
      return false;
    }
  }

  /// Intercambia el código de autorización por tokens
  static Future<Map<String, dynamic>?> _exchangeCodeForTokens(
    String code,
    String codeVerifier,
  ) async {
    try {
      _logger.i('🔄 Intercambiando código por tokens...');

      final tokenUrl =
          '${AuthConfig.keycloakIssuer}/protocol/openid-connect/token';

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': AuthConfig.clientId,
          'code': code,
          'redirect_uri': AuthConfig.webRedirectUrl,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        _logger.i('✅ Tokens obtenidos exitosamente');
        _logger.i(
            '📋 Token de acceso: ${tokenData['access_token']?.substring(0, 20) ?? 'null'}...');
        _logger.i(
            '📋 Refresh token: ${tokenData['refresh_token']?.substring(0, 20) ?? 'null'}...');
        _logger.i(
            '📋 ID token: ${tokenData['id_token']?.substring(0, 20) ?? 'null'}...');
        _logger.i('⏰ Expires in: ${tokenData['expires_in']} segundos');
        return tokenData;
      } else {
        _logger.e('❌ Error al obtener tokens: ${response.statusCode}');
        _logger.e('Respuesta: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error al intercambiar código por tokens: $e');
      return null;
    }
  }

  /// Refresca el token de acceso
  static Future<AuthUser?> _refreshToken(AuthUser user) async {
    try {
      final tokensJson =
          await WebStorageService.getJson(AuthConfig.tokensStorageKey);
      if (tokensJson == null) {
        _logger.w('Refresh token expirado, requiere re-autenticación');
        await signOut();
        return null;
      }

      final tokens = AuthTokens.fromJson(tokensJson);
      if (tokens.refreshTokenExpiry.isBefore(DateTime.now())) {
        _logger.w('Refresh token expirado, requiere re-autenticación');
        await signOut();
        return null;
      }

      final tokenData = await _refreshTokenFromKeycloak(tokens.refreshToken);

      if (tokenData == null) {
        _logger.w('No se pudo renovar el token');
        await signOut();
        return null;
      }

      // Actualizar usuario con nuevos tokens
      final updatedUser = user.copyWith(
        accessToken: tokenData['access_token'] ?? user.accessToken,
        refreshToken: tokenData['refresh_token'] ?? user.refreshToken,
        tokenExpiry: DateTime.now()
            .add(Duration(seconds: tokenData['expires_in'] ?? 3600)),
        idToken: tokenData['id_token'] ?? user.idToken,
      );

      await _saveUser(updatedUser);
      await _saveTokens(AuthTokens(
        accessToken: tokenData['access_token'] ?? tokens.accessToken,
        refreshToken: tokenData['refresh_token'] ?? tokens.refreshToken,
        idToken: tokenData['id_token'] ?? tokens.idToken,
        accessTokenExpiry: DateTime.now()
            .add(Duration(seconds: tokenData['expires_in'] ?? 3600)),
        refreshTokenExpiry: tokens.refreshTokenExpiry,
      ));

      _logger.i('Token renovado exitosamente');
      return updatedUser;
    } catch (e) {
      _logger.e('Error al renovar token: $e');
      await signOut();
      return null;
    }
  }

  /// Refresca token desde Keycloak
  static Future<Map<String, dynamic>?> _refreshTokenFromKeycloak(
      String refreshToken) async {
    try {
      _logger.i('🔄 Refrescando token...');

      final tokenUrl =
          '${AuthConfig.keycloakIssuer}/protocol/openid-connect/token';

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'client_id': AuthConfig.clientId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        _logger.i('✅ Token refrescado exitosamente');
        return tokenData;
      } else {
        _logger.e('❌ Error al refrescar token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error al refrescar token: $e');
      return null;
    }
  }

  /// Cierra sesión en Keycloak
  static Future<void> _logoutFromKeycloak(String refreshToken) async {
    try {
      _logger.i('🚪 Cerrando sesión en Keycloak...');

      final logoutUrl =
          '${AuthConfig.keycloakIssuer}/protocol/openid-connect/logout';

      await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': AuthConfig.clientId,
          'refresh_token': refreshToken,
        },
      );

      _logger.i('✅ Sesión cerrada en Keycloak');
    } catch (e) {
      _logger.e('❌ Error al cerrar sesión en Keycloak: $e');
    }
  }

  /// Construye la URL de autorización
  static String _buildAuthUrl(String codeChallenge, String state) {
    final params = {
      'response_type': 'code',
      'client_id': AuthConfig.clientId,
      'redirect_uri': AuthConfig.webRedirectUrl,
      'scope': AuthConfig.scopes.join(' '),
      // Incluir 'roles' para obtener los roles
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AuthConfig.keycloakIssuer}/protocol/openid-connect/auth?$queryString';
  }

  /// Genera un code verifier para PKCE
  static String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random();
    return List.generate(128, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Genera un code challenge para PKCE
  static String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Genera un estado aleatorio
  static String _generateState() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Decodifica el ID token JWT
  static Map<String, dynamic>? _decodeIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(resp) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error al decodificar ID token: $e');
      return null;
    }
  }

  /// Extrae roles del token JWT
  /// Busca en múltiples ubicaciones donde Keycloak puede incluir los roles
  static List<String> _extractRoles(Map<String, dynamic> userInfo) {
    try {
      _logger.d('🔍 Extrayendo roles del ID token');
      _logger.d('📋 UserInfo completo: $userInfo');

      // Verificar realm_access (formato estándar de Keycloak)
      final realmAccess = userInfo['realm_access'] as Map<String, dynamic>?;
      _logger.d('📋 Realm access: $realmAccess');

      if (realmAccess != null) {
        final roles = realmAccess['roles'] as List<dynamic>? ?? [];
        final roleList = roles.cast<String>();
        _logger.d('✅ Roles extraídos de realm_access: $roleList');
        return roleList;
      }

      // Fallback: verificar roles directos
      final directRoles = userInfo['roles'] as List<dynamic>? ?? [];
      if (directRoles.isNotEmpty) {
        _logger.d('✅ Roles directos encontrados: $directRoles');
        return directRoles.cast<String>();
      }

      // Fallback: verificar resource_access (roles de cliente)
      final resourceAccess =
          userInfo['resource_access'] as Map<String, dynamic>?;
      if (resourceAccess != null) {
        _logger.d('📋 Resource access: $resourceAccess');
        // Buscar roles del cliente Flutter
        final clientAccess =
            resourceAccess[AuthConfig.clientId] as Map<String, dynamic>?;
        if (clientAccess != null) {
          final clientRoles = clientAccess['roles'] as List<dynamic>? ?? [];
          if (clientRoles.isNotEmpty) {
            _logger.d('✅ Roles de cliente encontrados: $clientRoles');
            return clientRoles.cast<String>();
          }
        }
      }

      _logger.w('⚠️ No se encontraron roles en el token');
      _logger.d('📋 Estructura completa del token: ${userInfo.keys.toList()}');
      return [];
    } catch (e) {
      _logger.e('❌ Error al extraer roles: $e');
      return [];
    }
  }

  /// Guarda el usuario en localStorage
  static Future<void> _saveUser(AuthUser user) async {
    await WebStorageService.setJson(AuthConfig.userStorageKey, user.toJson());
  }

  /// Guarda los tokens en localStorage
  static Future<void> _saveTokens(AuthTokens tokens) async {
    await WebStorageService.setJson(
        AuthConfig.tokensStorageKey, tokens.toJson());
  }

  /// Limpia todos los datos de autenticación
  static Future<void> _clearUserData() async {
    try {
      _logger.i('🧹 Limpiando datos de autenticación...');

      // Limpiar datos de usuario y tokens
      _logger.i('🗑️ Eliminando auth_user_dev...');
      await WebStorageService.removeItem(AuthConfig.userStorageKey);

      _logger.i('🗑️ Eliminando auth_tokens_dev...');
      await WebStorageService.removeItem(AuthConfig.tokensStorageKey);

      // Limpiar también parámetros temporales de autenticación
      _logger.i('🗑️ Eliminando parámetros temporales...');
      await WebStorageService.removeItem('auth_code_verifier');
      await WebStorageService.removeItem('auth_state');

      // Verificar que se eliminaron
      final userExists =
          await WebStorageService.getItem(AuthConfig.userStorageKey);
      final tokensExist =
          await WebStorageService.getItem(AuthConfig.tokensStorageKey);

      if (userExists == null && tokensExist == null) {
        _logger.i('✅ Datos de autenticación limpiados correctamente');
      } else {
        _logger.w('⚠️ Algunos datos no se eliminaron correctamente');
        _logger.w(
            '   - auth_user_dev: ${userExists != null ? "existe" : "eliminado"}');
        _logger.w(
            '   - auth_tokens_dev: ${tokensExist != null ? "existe" : "eliminado"}');
      }
    } catch (e) {
      _logger.e('❌ Error al limpiar datos de autenticación: $e');
      // Intentar limpiar localStorage directamente como fallback
      try {
        if (kIsWeb) {
          html.window.localStorage.remove(AuthConfig.userStorageKey);
          html.window.localStorage.remove(AuthConfig.tokensStorageKey);
          html.window.localStorage.remove('auth_code_verifier');
          html.window.localStorage.remove('auth_state');
        }
      } catch (e2) {
        _logger.e('❌ Error en limpieza de fallback: $e2');
      }
    }
  }

  /// Limpia la URL del navegador
  static void _cleanUrl() {
    try {
      // Limpiar la URL sin cambiar la ruta para evitar bucles
      html.window.history.replaceState(null, '', '/');
    } catch (e) {
      _logger.w('No se pudo limpiar la URL: $e');
    }
  }
}
