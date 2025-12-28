

/// Stub para WebStorageService en plataformas no-web
class WebStorageService {
  /// Guarda un valor (no-op en plataformas no-web)
  static Future<void> setItem(String key, String value) async {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }

  /// Obtiene un valor (no-op en plataformas no-web)
  static Future<String?> getItem(String key) async {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }

  /// Elimina un valor (no-op en plataformas no-web)
  static Future<void> removeItem(String key) async {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }

  /// Guarda un objeto JSON (no-op en plataformas no-web)
  static Future<void> setJson(String key, Map<String, dynamic> json) async {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }

  /// Obtiene un objeto JSON (no-op en plataformas no-web)
  static Future<Map<String, dynamic>?> getJson(String key) async {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }

  /// Limpia todo el almacenamiento (no-op en plataformas no-web)
  static Future<void> clear() async {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }

  /// Verifica si el almacenamiento está disponible
  static bool get isAvailable => false;

  /// Obtiene todas las claves (no-op en plataformas no-web)
  static List<String> getKeys() {
    throw UnsupportedError('WebStorageService solo está disponible en web');
  }
}
