import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/auth_config.dart';
import '../../models/auth/auth_user_model.dart';
import 'web_auth_service.dart';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final Logger _logger = Logger();

  // Configuración de Keycloak
  KeycloakConfig get keycloakConfig {
    return KeycloakConfig(
      issuer: AuthConfig.keycloakIssuer,
      clientId: AuthConfig.clientId,
      redirectUrl: AuthConfig.redirectUrl,
      discoveryUrl: AuthConfig.discoveryUrl,
      scopes: AuthConfig.scopes,
    );
  }

  /// Inicia el flujo de autenticación OIDC con PKCE
  Future<AuthUser?> signIn([BuildContext? context]) async {
    try {
      _logger.i('Iniciando flujo de autenticación OIDC');

      // Usar WebAuthService para todas las plataformas (evita problemas de FlutterAppAuth)
      _logger.i('Usando WebAuthService para autenticación');

      if (context == null) {
        _logger.e('Context es requerido para WebAuthService');
        return null;
      }

      final tokenData = await WebAuthService.signInWithWebView(context);

      if (tokenData == null) {
        _logger.w('No se recibió respuesta de autorización');
        return null;
      }

      _logger.i('Autenticación exitosa, procesando tokens');
      _logger.i(
          '📋 Token de acceso recibido: ${tokenData['access_token']?.substring(0, 20) ?? 'null'}...');
      _logger.i(
          '📋 Refresh token recibido: ${tokenData['refresh_token']?.substring(0, 20) ?? 'null'}...');
      _logger.i(
          '📋 ID token recibido: ${tokenData['id_token']?.substring(0, 20) ?? 'null'}...');
      _logger.i('⏰ Expires in: ${tokenData['expires_in']} segundos');

      // Decodificar el ID token para obtener información del usuario
      final userInfo = _decodeIdToken(tokenData['id_token'] ?? '');
      if (userInfo == null) {
        _logger.e('Error al decodificar ID token');
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
        accessToken: tokenData['access_token'] ?? '',
        refreshToken: tokenData['refresh_token'] ?? '',
        tokenExpiry: DateTime.now().add(Duration(
            seconds: tokenData['expires_in'] ??
                AuthConfig.accessTokenExpiryHours * 3600)),
        idToken: tokenData['id_token'] ?? '',
      );

      // Guardar usuario y tokens
      await _saveUser(authUser);
      await _saveTokens(AuthTokens(
        accessToken: tokenData['access_token'] ?? '',
        refreshToken: tokenData['refresh_token'] ?? '',
        idToken: tokenData['id_token'] ?? '',
        accessTokenExpiry: DateTime.now()
            .add(Duration(seconds: tokenData['expires_in'] ?? 3600)),
        refreshTokenExpiry: DateTime.now().add(const Duration(days: 30)),
      ));

      _logger.i('Usuario autenticado: ${authUser.username}');
      _logger.i(
          '🎉 Autenticación completada exitosamente - el usuario será redirigido automáticamente');
      return authUser;
    } catch (e, stackTrace) {
      _logger.e('Error en autenticación', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Cierra la sesión del usuario
  Future<void> signOut() async {
    try {
      _logger.i('Cerrando sesión del usuario');

      // Para web, usar WebAuthService que maneja todo el proceso
      if (kIsWeb) {
        await WebAuthService.signOut();
        // WebAuthService maneja la limpieza y redirección
        return;
      }

      // Para móvil, usar la lógica existente
      final tokens = await _getTokens();
      if (tokens?.refreshToken != null) {
        await WebAuthService.signOut(tokens!.refreshToken);
      }

      // Limpiar datos locales
      await _clearUserData();
      _logger.i('Sesión cerrada exitosamente');
    } catch (e, stackTrace) {
      _logger.e('Error al cerrar sesión', error: e, stackTrace: stackTrace);
      // Aún así, limpiar datos locales
      await _clearUserData();
    }
  }

  /// Obtiene el usuario autenticado actual
  Future<AuthUser?> getCurrentUser() async {
    try {
      // Usar WebAuthService para web
      if (kIsWeb) {
        return await WebAuthService.getCurrentUser();
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AuthConfig.userStorageKey);

      if (userJson == null) {
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);

      // Verificar si el token aún es válido
      if (user.tokenExpiry.isBefore(DateTime.now())) {
        _logger.i('Token expirado, intentando renovar');
        final refreshedUser = await _refreshToken(user);
        return refreshedUser;
      }

      return user;
    } catch (e, stackTrace) {
      _logger.e('Error al obtener usuario actual',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Procesa el callback de autenticación en web
  Future<AuthUser?> processWebCallback() async {
    if (kIsWeb) {
      return await WebAuthService.processCallback();
    }
    return null;
  }

  /// Verifica si el usuario existe en el backend
  Future<bool> checkUserExists(String keycloakId) async {
    try {
      // Usar WebAuthService para web
      if (kIsWeb) {
        return await WebAuthService.checkUserExists(keycloakId);
      }

      final tokens = await _getTokens();
      if (tokens == null) {
        _logger.w('❌ No se encontraron tokens para verificar usuario');
        return false;
      }

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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.w('⏰ Timeout al verificar usuario en backend');
          throw Exception('Timeout al verificar usuario');
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
    } catch (e, stackTrace) {
      _logger.e('❌ Error al verificar existencia del usuario',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Renueva el token de acceso usando el refresh token
  Future<AuthUser?> _refreshToken(AuthUser user) async {
    try {
      final tokens = await _getTokens();
      if (tokens == null ||
          tokens.refreshTokenExpiry.isBefore(DateTime.now())) {
        _logger.w('Refresh token expirado, requiere re-autenticación');
        await signOut();
        return null;
      }

      // Usar WebAuthService para renovar tokens
      final tokenData = await WebAuthService.refreshToken(tokens.refreshToken);

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
    } catch (e, stackTrace) {
      _logger.e('Error al renovar token', error: e, stackTrace: stackTrace);
      await signOut();
      return null;
    }
  }

  /// Genera un code verifier para PKCE
  String _generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(AuthConfig.codeVerifierLength,
        (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Genera un code challenge para PKCE
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Decodifica el ID token JWT
  Map<String, dynamic>? _decodeIdToken(String idToken) {
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
  List<String> _extractRoles(Map<String, dynamic> userInfo) {
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
        final clientAccess = resourceAccess['iasy-stock-flutter-client']
            as Map<String, dynamic>?;
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

  /// Guarda el usuario en SharedPreferences
  Future<void> _saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthConfig.userStorageKey, jsonEncode(user.toJson()));
  }

  /// Guarda los tokens en SharedPreferences
  Future<void> _saveTokens(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AuthConfig.tokensStorageKey, jsonEncode(tokens.toJson()));
  }

  /// Obtiene los tokens guardados
  Future<AuthTokens?> _getTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = prefs.getString(AuthConfig.tokensStorageKey);

      if (tokensJson == null) {
        return null;
      }

      final tokensMap = jsonDecode(tokensJson) as Map<String, dynamic>;
      return AuthTokens.fromJson(tokensMap);
    } catch (e) {
      _logger.e('Error al obtener tokens: $e');
      return null;
    }
  }

  /// Limpia todos los datos de autenticación
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthConfig.userStorageKey);
    await prefs.remove(AuthConfig.tokensStorageKey);
  }
}
