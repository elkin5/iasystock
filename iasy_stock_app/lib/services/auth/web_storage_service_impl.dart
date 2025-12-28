import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Servicio de almacenamiento específico para web usando localStorage
class WebStorageService {
  static final Logger _logger = Logger();

  /// Guarda un valor en localStorage
  static Future<void> setItem(String key, String value) async {
    if (kIsWeb) {
      try {
        html.window.localStorage[key] = value;
        _logger.d('✅ Guardado en localStorage: $key');
      } catch (e) {
        _logger.e('❌ Error al guardar en localStorage: $e');
        rethrow;
      }
    } else {
      throw UnsupportedError('WebStorageService solo está disponible en web');
    }
  }

  /// Obtiene un valor de localStorage
  static Future<String?> getItem(String key) async {
    if (kIsWeb) {
      try {
        final value = html.window.localStorage[key];
        _logger.d(
            '📖 Leído de localStorage: $key = ${value != null ? "existe" : "null"}');
        return value;
      } catch (e) {
        _logger.e('❌ Error al leer de localStorage: $e');
        return null;
      }
    } else {
      throw UnsupportedError('WebStorageService solo está disponible en web');
    }
  }

  /// Elimina un valor de localStorage
  static Future<void> removeItem(String key) async {
    if (kIsWeb) {
      try {
        html.window.localStorage.remove(key);
        _logger.d('🗑️ Eliminado de localStorage: $key');
      } catch (e) {
        _logger.e('❌ Error al eliminar de localStorage: $e');
        rethrow;
      }
    } else {
      throw UnsupportedError('WebStorageService solo está disponible en web');
    }
  }

  /// Guarda un objeto JSON en localStorage
  static Future<void> setJson(String key, Map<String, dynamic> json) async {
    await setItem(key, jsonEncode(json));
  }

  /// Obtiene un objeto JSON de localStorage
  static Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await getItem(key);
    if (value != null) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (e) {
        _logger.e('❌ Error al decodificar JSON de localStorage: $e');
        return null;
      }
    }
    return null;
  }

  /// Limpia todo el localStorage (solo para desarrollo)
  static Future<void> clear() async {
    if (kIsWeb) {
      try {
        html.window.localStorage.clear();
        _logger.d('🧹 localStorage limpiado');
      } catch (e) {
        _logger.e('❌ Error al limpiar localStorage: $e');
        rethrow;
      }
    } else {
      throw UnsupportedError('WebStorageService solo está disponible en web');
    }
  }

  /// Verifica si localStorage está disponible
  static bool get isAvailable => kIsWeb;

  /// Obtiene todas las claves del localStorage
  static List<String> getKeys() {
    if (kIsWeb) {
      try {
        return html.window.localStorage.keys.toList();
      } catch (e) {
        _logger.e('❌ Error al obtener claves de localStorage: $e');
        return [];
      }
    } else {
      throw UnsupportedError('WebStorageService solo está disponible en web');
    }
  }
}
