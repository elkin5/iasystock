import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../config/app_constants.dart';
import '../theme/app_colors.dart';

/// Utilidades para manejo de errores y respuestas de la aplicación
class ErrorHandler {
  static final Logger _logger = Logger();

  /// Maneja errores de Dio y los convierte en mensajes amigables
  static String handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppConstants.errorNetworkConnection;

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Operación cancelada';

      case DioExceptionType.connectionError:
        return AppConstants.errorNetworkConnection;

      case DioExceptionType.badCertificate:
        return 'Error de certificado SSL';

      case DioExceptionType.unknown:
        return 'Error desconocido: ${error.message}';
    }
  }

  /// Maneja errores HTTP específicos
  static String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return AppConstants.errorValidation;
      case 401:
        return AppConstants.errorUnauthorized;
      case 403:
        return AppConstants.errorForbidden;
      case 404:
        return AppConstants.errorNotFound;
      case 500:
      case 502:
      case 503:
        return AppConstants.errorServerError;
      default:
        return AppConstants.errorServerError;
    }
  }

  /// Muestra un SnackBar con el mensaje de error
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra un SnackBar con el mensaje de éxito
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success(context),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Logs un error con contexto
  static void logError(String context, dynamic error,
      [StackTrace? stackTrace]) {
    _logger.e('Error en $context', error: error, stackTrace: stackTrace);
  }

  /// Logs información de debug
  static void logInfo(String message) {
    _logger.i(message);
  }

  /// Logs advertencias
  static void logWarning(String message) {
    _logger.w(message);
  }
}
