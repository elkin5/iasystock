import 'dart:async';

import 'package:logger/logger.dart';

import '../../config/auth_config.dart';
import '../../cubits/auth/auth_cubit.dart';

/// Servicio para monitorear la validez del token y renovarlo automáticamente
class TokenMonitorService {
  final AuthCubit _authCubit;
  final Logger _logger = Logger();

  Timer? _tokenCheckTimer;
  static const Duration _checkInterval =
      Duration(minutes: 5); // Verificar cada 5 minutos
  DateTime? _lastRefreshTime;

  TokenMonitorService({required AuthCubit authCubit}) : _authCubit = authCubit;

  /// Inicia el monitoreo de tokens
  void startMonitoring() {
    _logger.i('Iniciando monitoreo de tokens');

    // Cancelar cualquier timer existente
    _tokenCheckTimer?.cancel();

    // Crear nuevo timer que se ejecuta cada minuto
    _tokenCheckTimer = Timer.periodic(_checkInterval, (timer) async {
      await _checkAndRefreshToken();
    });

    // Realizar verificación inicial
    _checkAndRefreshToken();
  }

  /// Detiene el monitoreo de tokens
  void stopMonitoring() {
    _logger.i('Deteniendo monitoreo de tokens');
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = null;
    _lastRefreshTime = null;
  }

  /// Verifica el estado del token y lo renueva si es necesario
  Future<void> _checkAndRefreshToken() async {
    try {
      // Si no hay usuario autenticado, no hacer nada
      if (!_authCubit.isAuthenticated) {
        _logger
            .d('No hay usuario autenticado, omitiendo verificación de token');
        return;
      }

      final user = _authCubit.currentUser;
      if (user == null) {
        _logger.d('Usuario no encontrado, omitiendo verificación de token');
        return;
      }

      // Calcular tiempo hasta expiración
      final now = DateTime.now();
      final expiry = user.tokenExpiry;
      final timeUntilExpiry = expiry.difference(now);

      // Si el token ya expiró, no intentar renovar
      if (timeUntilExpiry.isNegative) {
        _logger.w('Token ya expirado, deteniendo monitoreo');
        stopMonitoring();
        return;
      }

      _logger.d(
          'Tiempo hasta expiración del token: ${timeUntilExpiry.inMinutes} minutos');

      // Solo renovar si el token está próximo a expirar (menos de 5 minutos)
      // y no se ha renovado recientemente (evitar bucles)
      if (timeUntilExpiry.inMinutes <=
              AuthConfig.tokenRefreshThresholdMinutes &&
          timeUntilExpiry.inMinutes > 0) {
        // Verificar si ya se renovó recientemente (últimos 5 minutos)
        final lastRefresh = _lastRefreshTime;
        if (lastRefresh != null && now.difference(lastRefresh).inMinutes < 5) {
          _logger.d('Token renovado recientemente, omitiendo renovación');
          return;
        }

        _logger.i('Token próximo a expirar, iniciando renovación automática');
        _lastRefreshTime = now;

        // Renovar el token
        await _authCubit.refreshToken();

        if (_authCubit.isAuthenticated) {
          _logger.i('Token renovado exitosamente');
        } else {
          _logger.w(
              'No se pudo renovar el token, el usuario deberá volver a autenticarse');
          stopMonitoring(); // Detener el monitoreo si no se pudo renovar
        }
      } else if (timeUntilExpiry.inMinutes >
          AuthConfig.tokenRefreshThresholdMinutes) {
        _logger.d('Token válido por ${timeUntilExpiry.inMinutes} minutos más');
      } else {
        _logger.d(
            'Token expira en ${timeUntilExpiry.inMinutes} minutos, no necesita renovación aún');
      }
    } catch (e, stackTrace) {
      _logger.e('Error al verificar/renovar token',
          error: e, stackTrace: stackTrace);
      // En caso de error, detener el monitoreo para evitar bucles
      stopMonitoring();
    }
  }

  /// Fuerza una verificación inmediata del token
  Future<void> forceTokenCheck() async {
    _logger.i('Forzando verificación de token');
    await _checkAndRefreshToken();
  }

  /// Verifica si el servicio está activo
  bool get isMonitoring =>
      _tokenCheckTimer != null && _tokenCheckTimer!.isActive;

  /// Dispose del servicio
  void dispose() {
    stopMonitoring();
  }
}
