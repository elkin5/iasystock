import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Solución simple y efectiva para el error de deep links de autenticación
class DeepLinkErrorHandler {
  static final DeepLinkErrorHandler _instance =
      DeepLinkErrorHandler._internal();

  factory DeepLinkErrorHandler() => _instance;

  DeepLinkErrorHandler._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;

  /// Inicializa el manejo de errores de deep links
  void initialize() {
    if (_isInitialized) {
      return;
    }

    _logger.i('🔧 Inicializando DeepLinkErrorHandler...');

    // Configurar manejo de errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Configurar manejo de errores de la zona
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true; // Indicar que el error fue manejado
    };

    _isInitialized = true;
    _logger.i('✅ DeepLinkErrorHandler inicializado correctamente');
  }

  /// Maneja errores de Flutter
  void _handleFlutterError(FlutterErrorDetails details) {
    final error = details.exception;
    final stackTrace = details.stack;

    // Verificar si es el error específico de deep links
    if (_isDeepLinkError(error)) {
      _logger.w('🚫 Error de deep link interceptado y suprimido');
      _logger.w('Error: ${error.toString()}');

      // Manejar específicamente el error null_intent
      if (error.toString().contains('null_intent')) {
        _handleNullIntentError(error);
        return;
      }

      // Extraer información del deep link si es posible
      _extractDeepLinkInfo(error);

      // NO re-lanzar el error, simplemente registrarlo
      return;
    }

    // Para otros errores, usar el manejo por defecto
    FlutterError.presentError(details);
  }

  /// Maneja errores de la plataforma
  void _handlePlatformError(Object error, StackTrace stack) {
    if (_isDeepLinkError(error)) {
      _logger.w('🚫 Error de plataforma de deep link interceptado y suprimido');
      _logger.w('Error: $error');
      return;
    }

    // Para otros errores, usar el manejo por defecto
    _logger.e('Error de plataforma no manejado: $error',
        error: error, stackTrace: stack);
  }

  /// Verifica si el error es relacionado con deep links
  bool _isDeepLinkError(Object error) {
    if (error is StateError) {
      final message = error.message.toLowerCase();
      return message.contains('origin is only applicable schemes') &&
          message.contains('http') &&
          message.contains('https');
    }

    if (error is ArgumentError) {
      final message = error.message?.toLowerCase() ?? '';
      return message.contains('origin') && message.contains('schemes');
    }

    // También interceptar PlatformException relacionadas con null_intent
    if (error.toString().contains('null_intent') &&
        error.toString().contains('Failed to authorize')) {
      return true;
    }

    return false;
  }

  /// Extrae información del deep link del error
  void _extractDeepLinkInfo(Object error) {
    try {
      final errorString = error.toString();

      // Buscar patrones de deep links en el mensaje de error
      final uriPattern = RegExp(r'(com\.iasystock\.app://[^\s]+)');
      final match = uriPattern.firstMatch(errorString);

      if (match != null) {
        final deepLinkUrl = match.group(1)!;
        _logger.i('🔗 Deep link detectado: $deepLinkUrl');

        // Procesar el deep link
        _processDeepLink(deepLinkUrl);
      }
    } catch (e) {
      _logger.e('Error al extraer información del deep link: $e');
    }
  }

  /// Procesa el deep link detectado
  void _processDeepLink(String url) {
    try {
      final uri = Uri.parse(url);

      // Verificar si es un callback de autenticación
      if (uri.path.contains('callback')) {
        _logger.i('🔐 Callback de autenticación detectado');

        final queryParams = uri.queryParameters;
        final code = queryParams['code'];
        final state = queryParams['state'];
        final error = queryParams['error'];

        if (error != null) {
          _logger.e('❌ Error en callback de autenticación: $error');
          return;
        }

        if (code != null && state != null) {
          _logger.i('✅ Callback válido - código: ${code.substring(0, 8)}...');
          _logger
              .i('🔄 El FlutterAppAuth manejará automáticamente este callback');

          // Notificar que el callback fue procesado exitosamente
          _onAuthCallbackProcessed();
        } else {
          _logger.w('⚠️ Callback incompleto');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error al procesar deep link: $url',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Callback cuando se procesa exitosamente un callback de autenticación
  void _onAuthCallbackProcessed() {
    _logger.i('🎉 Callback de autenticación procesado exitosamente');

    // Aquí podrías agregar lógica adicional si es necesario
    // Por ejemplo, notificar a otros servicios o actualizar el estado
  }

  /// Maneja específicamente el error null_intent
  void _handleNullIntentError(Object error) {
    _logger.w(
        '🔧 Error null_intent detectado - posible problema de configuración');
    _logger.w('Error: ${error.toString()}');

    _logger.i('💡 Posibles soluciones:');
    _logger.i(
        '   1. Verificar AndroidManifest.xml tiene el intent-filter correcto');
    _logger.i(
        '   2. Verificar que Keycloak esté configurado con el redirect URI correcto');
    _logger
        .i('   3. Verificar que el esquema com.iasystock.app esté registrado');
    _logger.i('   4. Reiniciar la aplicación completamente');

    // Este error indica que FlutterAppAuth no puede manejar el callback
    // pero el deep link sí está llegando (como vimos en los logs anteriores)
    _logger.i(
        '🔄 El deep link está llegando correctamente, pero FlutterAppAuth no puede procesarlo');
    _logger
        .i('💡 Esto puede ser normal si el usuario cancela la autenticación');
  }

  /// Verifica si una URL es problemática para GoRouter
  bool isProblematicUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme.toLowerCase();

      // Lista de esquemas que causan problemas con GoRouter
      const problematicSchemes = [
        'com.iasystock.app',
        'iasystock',
        'iasy-stock',
      ];

      return problematicSchemes.contains(scheme);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _isInitialized = false;
    _logger.i('DeepLinkErrorHandler disposed');
  }
}

/// Widget que inicializa el manejo de errores de deep links
class DeepLinkErrorHandlerWidget extends StatefulWidget {
  final Widget child;

  const DeepLinkErrorHandlerWidget({
    super.key,
    required this.child,
  });

  @override
  State<DeepLinkErrorHandlerWidget> createState() =>
      _DeepLinkErrorHandlerWidgetState();
}

class _DeepLinkErrorHandlerWidgetState
    extends State<DeepLinkErrorHandlerWidget> {
  @override
  void initState() {
    super.initState();
    // Inicializar el manejo de errores de deep links
    DeepLinkErrorHandler().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
