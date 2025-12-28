import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/auth_config.dart';
import '../cubits/auth/auth_cubit.dart';
import 'auth/auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService authService;
  final AuthCubit authCubit;
  final Logger _logger = Logger();

  AuthInterceptor({required this.authService, required this.authCubit});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Verificar si la seguridad está desactivada
    if (AuthConfig.disableSecurity) {
      _logger.w(
          '🔓 SEGURIDAD DESACTIVADA - Saltando autenticación para: ${options.path}');
      handler.next(options);
      return;
    }

    // Obtener el token actual
    final token = authCubit.accessToken;
    final isAuthenticated = authCubit.isAuthenticated;

    _logger.i('🔍 AuthInterceptor - Request: ${options.path}');
    _logger.i('🔍 Estado de autenticación: $isAuthenticated');
    _logger.i('🔍 Token disponible: ${token != null ? 'Sí' : 'No'}');

    if (token != null) {
      // Agregar el token al header Authorization
      options.headers['Authorization'] = 'Bearer $token';
      _logger.i('✅ Token agregado al request: ${options.path}');
      _logger.i('🔑 Token (primeros 20 chars): ${token.substring(0, 20)}...');
    } else {
      _logger.w('⚠️ No hay token disponible para el request: ${options.path}');
      _logger.w('⚠️ El usuario necesita autenticarse primero');
    }

    // Verificar si el token está próximo a expirar
    if (authCubit.isTokenExpiringSoon && token != null) {
      _logger.i('Token próximo a expirar, renovando...');
      await authCubit.refreshToken();

      // Actualizar el token en el request si se renovó exitosamente
      final newToken = authCubit.accessToken;
      if (newToken != null && newToken != token) {
        options.headers['Authorization'] = 'Bearer $newToken';
        _logger.d('Token renovado y actualizado en el request');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si la seguridad está desactivada, no manejar errores de autenticación
    if (AuthConfig.disableSecurity) {
      _logger.w(
          '🔓 SEGURIDAD DESACTIVADA - No manejando errores de autenticación');
      handler.next(err);
      return;
    }

    if (err.response?.statusCode == 401) {
      _logger.w('Error 401 - Token inválido o expirado');

      // Intentar renovar el token
      await authCubit.refreshToken();

      // Si el token se renovó exitosamente, reintentar la petición
      if (authCubit.isAuthenticated) {
        try {
          _logger.i('Reintentando petición con token renovado');

          // Clonar la petición original con el nuevo token
          final newToken = authCubit.accessToken;
          if (newToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

            // Reintentar la petición
            final response = await Dio().fetch(err.requestOptions);
            return handler.resolve(response);
          }
        } catch (e) {
          _logger.e('Error al reintentar petición: $e');
        }
      } else {
        // Si no se pudo renovar el token, redirigir al login
        _logger.w('No se pudo renovar el token, cerrando sesión');
        await authCubit.signOut();
      }
    } else if (err.response?.statusCode == 403) {
      _logger.w('Error 403 - Acceso prohibido: ${err.requestOptions.path}');
      // No hay mucho que hacer aquí, el usuario no tiene permisos
    }

    handler.next(err);
  }
}
