import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NotificationHelper {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger(context),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success(context),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  /// Extrae el mensaje de error específico de una DioException
  static String extractErrorMessage(DioException e, {String? defaultMessage}) {
    final defaultMsg = defaultMessage ?? 'Error interno del servidor';

    if (e.response?.data == null) {
      return defaultMsg;
    }

    final responseData = e.response!.data;

    // Intentar obtener el mensaje específico del error del backend
    if (responseData is Map<String, dynamic>) {
      // Buscar en details.exceptionMessage (mensaje específico del backend)
      if (responseData['details'] != null &&
          responseData['details'] is Map<String, dynamic> &&
          responseData['details']['exceptionMessage'] != null) {
        return responseData['details']['exceptionMessage'];
      }

      // Buscar en message (mensaje general del backend)
      if (responseData['message'] != null) {
        return responseData['message'];
      }

      // Buscar en error (mensaje de error estándar)
      if (responseData['error'] != null) {
        return responseData['error'];
      }
    }

    return defaultMsg;
  }

  /// Muestra un error específico extraído de una DioException
  static void showDioError(BuildContext context, DioException e,
      {String? defaultMessage}) {
    final message = extractErrorMessage(e, defaultMessage: defaultMessage);
    showError(context, message);
  }
}
