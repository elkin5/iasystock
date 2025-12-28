import '../../models/auth/auth_user_model.dart';

/// Stub para WebAuthImpl en plataformas no-web
class WebAuthImpl {
  /// Inicia el flujo de autenticación web (no-op en plataformas no-web)
  static Future<AuthUser?> signIn() async {
    throw UnsupportedError('WebAuthImpl solo está disponible en web');
  }

  /// Procesa el callback de autenticación web (no-op en plataformas no-web)
  static Future<AuthUser?> processCallback() async {
    throw UnsupportedError('WebAuthImpl solo está disponible en web');
  }

  /// Obtiene el usuario actual desde localStorage (no-op en plataformas no-web)
  static Future<AuthUser?> getCurrentUser() async {
    throw UnsupportedError('WebAuthImpl solo está disponible en web');
  }

  /// Cierra la sesión del usuario (no-op en plataformas no-web)
  static Future<void> signOut() async {
    throw UnsupportedError('WebAuthImpl solo está disponible en web');
  }

  /// Verifica si el usuario existe en el backend (no-op en plataformas no-web)
  static Future<bool> checkUserExists(String keycloakId) async {
    throw UnsupportedError('WebAuthImpl solo está disponible en web');
  }
}
