import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/auth_config.dart';
import '../../models/auth/auth_user_model.dart';
import 'web_auth_stub.dart' if (dart.library.html) 'web_auth_impl.dart';

/// Clase para manejar el estado del callback y evitar procesamiento múltiple
class CallbackState {
  bool _isProcessed = false;

  bool get isProcessed => _isProcessed;

  void markAsProcessed() {
    _isProcessed = true;
  }
}

/// Servicio de autenticación web que evita los problemas de FlutterAppAuth
class WebAuthService {
  static final Logger _logger = Logger();

  /// Realiza la autenticación usando WebView (móvil) o redirección directa (web)
  static Future<Map<String, dynamic>?> signInWithWebView(
      BuildContext context) async {
    try {
      _logger.i('🌐 Iniciando autenticación web...');

      // Si estamos en web, usar la implementación nativa de web
      if (kIsWeb) {
        _logger.i('🌐 Usando autenticación nativa de web');
        final user = await WebAuthImpl.signIn();
        // En web, signIn() redirige la página, así que no retornamos nada aquí
        return null;
      }

      // Para móvil, usar WebView
      _logger.i('📱 Usando WebView para móvil');

      // Generar parámetros PKCE
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      // Construir URL de autorización
      final authUrl = _buildAuthUrl(codeChallenge, state);

      _logger.i('🔗 URL de autorización: $authUrl');

      // Mostrar WebView para autenticación
      final result = await _showAuthWebView(context, authUrl, codeVerifier);

      if (result != null) {
        _logger.i('✅ Autenticación exitosa');
        return result;
      } else {
        _logger.w('❌ Autenticación cancelada o fallida');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error en autenticación web: $e');
      return null;
    }
  }

  /// Muestra el WebView para autenticación
  static Future<Map<String, dynamic>?> _showAuthWebView(
    BuildContext context,
    String authUrl,
    String codeVerifier,
  ) async {
    final Completer<Map<String, dynamic>?> completer = Completer();
    final CallbackState callbackState = CallbackState();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop && !completer.isCompleted) {
            completer.complete(null);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Iniciar Sesión'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              },
            ),
          ),
          body: WebViewWidget(
            controller: _createWebViewController(
                authUrl, codeVerifier, completer, dialogContext, callbackState),
          ),
        ),
      ),
    );

    return completer.future;
  }

  /// Crea el controlador del WebView
  static WebViewController _createWebViewController(
    String authUrl,
    String codeVerifier,
    Completer<Map<String, dynamic>?> completer,
    BuildContext dialogContext,
    CallbackState callbackState,
  ) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            _logger.i('🔗 Navegando a: ${request.url}');

            // Verificar si es el callback de autenticación
            if (request.url.startsWith('com.iasystock.app://login-callback')) {
              if (!callbackState.isProcessed) {
                callbackState.markAsProcessed();
                _handleAuthCallback(
                    request.url, codeVerifier, completer, dialogContext);
                return NavigationDecision.prevent;
              } else {
                _logger.w('⚠️ Callback ya procesado, ignorando navegación');
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            _logger.i('📄 Página cargada: $url');
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));

    return controller;
  }

  /// Maneja el callback de autenticación
  static void _handleAuthCallback(
    String callbackUrl,
    String codeVerifier,
    Completer<Map<String, dynamic>?> completer,
    BuildContext dialogContext,
  ) async {
    try {
      _logger.i('🔐 Procesando callback de autenticación...');

      // Verificar si el completer ya fue completado
      if (completer.isCompleted) {
        _logger.w('⚠️ Callback ya fue procesado, ignorando...');
        return;
      }

      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        _logger.e('❌ Error en callback: $error');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        Navigator.of(dialogContext).pop();
        return;
      }

      if (code == null) {
        _logger.e('❌ Código de autorización no encontrado');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        Navigator.of(dialogContext).pop();
        return;
      }

      _logger
          .i('✅ Código de autorización recibido: ${code.substring(0, 8)}...');

      // Intercambiar código por tokens
      final tokens = await _exchangeCodeForTokens(code, codeVerifier);

      if (tokens != null) {
        _logger.i('🎉 Tokens obtenidos exitosamente');
        if (!completer.isCompleted) {
          completer.complete(tokens);
        }
        // Cerrar el diálogo automáticamente después del éxito
        Navigator.of(dialogContext).pop();
      } else {
        _logger.e('❌ Error al obtener tokens');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        Navigator.of(dialogContext).pop();
      }
    } catch (e) {
      _logger.e('❌ Error al procesar callback: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      Navigator.of(dialogContext).pop();
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
          'redirect_uri': AuthConfig.redirectUrl,
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

  /// Construye la URL de autorización
  static String _buildAuthUrl(String codeChallenge, String state) {
    final params = {
      'response_type': 'code',
      'client_id': AuthConfig.clientId,
      'redirect_uri': AuthConfig.redirectUrl,
      'scope': 'openid profile email',
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

  /// Refresca el token de acceso
  static Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
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

  /// Obtiene el usuario actual
  static Future<AuthUser?> getCurrentUser() async {
    if (kIsWeb) {
      return await WebAuthImpl.getCurrentUser();
    }
    // Para móvil, este método no se usa directamente
    return null;
  }

  /// Procesa callback web
  static Future<AuthUser?> processCallback() async {
    if (kIsWeb) {
      return await WebAuthImpl.processCallback();
    }
    // Para móvil, este método no se usa directamente
    return null;
  }

  /// Verifica si el usuario existe
  static Future<bool> checkUserExists(String keycloakId) async {
    if (kIsWeb) {
      return await WebAuthImpl.checkUserExists(keycloakId);
    }
    // Para móvil, retornar true por defecto
    return true;
  }

  /// Cierra la sesión
  static Future<void> signOut([String? refreshToken]) async {
    if (kIsWeb) {
      await WebAuthImpl.signOut();
    } else {
      // Para móvil, usar la lógica existente
      await _signOutMobile(refreshToken);
    }
  }

  /// Cierra la sesión en móvil
  static Future<void> _signOutMobile(String? refreshToken) async {
    try {
      _logger.i('🚪 Cerrando sesión en móvil...');

      if (refreshToken != null) {
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
      }

      _logger.i('✅ Sesión cerrada exitosamente');
    } catch (e) {
      _logger.e('❌ Error al cerrar sesión: $e');
    }
  }
}
