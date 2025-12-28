import 'dart:async';

import 'package:logger/logger.dart';

final Logger log = Logger();

/// Servicio de cache inteligente para URLs firmadas temporales
///
/// Maneja el cache de URLs firmadas con expiración automática,
/// evitando llamadas innecesarias al backend para renovar URLs
/// que aún son válidas.
///
/// Características:
/// - Cache con TTL (Time To Live)
/// - Limpieza automática de URLs expiradas
/// - Optimización de memoria
/// - Thread-safe
class SecureImageCacheService {
  // Singleton
  static final SecureImageCacheService _instance =
      SecureImageCacheService._internal();

  factory SecureImageCacheService() => _instance;

  SecureImageCacheService._internal() {
    _startCleanupTimer();
  }

  /// Cache de URLs firmadas con información de expiración
  final Map<String, _CachedUrl> _urlCache = {};

  /// Timer para limpieza periódica de cache
  Timer? _cleanupTimer;

  /// Duración por defecto antes de considerar URL expirada (22 horas)
  /// Usar menos que las 24 horas del backend para seguridad extra
  static const Duration _defaultCacheDuration = Duration(hours: 22);

  /// Intervalo de limpieza del cache (cada hora)
  static const Duration _cleanupInterval = Duration(hours: 1);

  /// Genera una clave única para el cache basada en productId
  String _generateCacheKey(int productId) => 'product_$productId';

  /// Guarda una URL firmada en el cache
  void cacheImageUrl(int productId, String signedUrl) {
    final key = _generateCacheKey(productId);
    final expiry = DateTime.now().add(_defaultCacheDuration);

    _urlCache[key] = _CachedUrl(
      url: signedUrl,
      expiresAt: expiry,
      productId: productId,
    );

    log.d('URL cacheada para producto $productId, expira en: $expiry');
  }

  /// Obtiene una URL firmada del cache si está disponible y no ha expirado
  String? getCachedImageUrl(int productId) {
    final key = _generateCacheKey(productId);
    final cachedUrl = _urlCache[key];

    if (cachedUrl == null) {
      log.d('No hay URL en cache para producto $productId');
      return null;
    }

    // Verificar si la URL ha expirado
    if (cachedUrl.isExpired()) {
      log.d('URL en cache expirada para producto $productId, removiendo...');
      _urlCache.remove(key);
      return null;
    }

    log.d('URL obtenida del cache para producto $productId');
    return cachedUrl.url;
  }

  /// Verifica si hay una URL válida en cache
  bool hasValidCachedUrl(int productId) {
    return getCachedImageUrl(productId) != null;
  }

  /// Remueve una URL del cache (útil cuando sabemos que ha expirado)
  void invalidateCache(int productId) {
    final key = _generateCacheKey(productId);
    final removed = _urlCache.remove(key);

    if (removed != null) {
      log.d('Cache invalidado para producto $productId');
    }
  }

  /// Limpia todas las URLs expiradas del cache
  void cleanExpiredUrls() {
    final expiredKeys = <String>[];

    _urlCache.forEach((key, cachedUrl) {
      if (cachedUrl.isExpired()) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      final cachedUrl = _urlCache.remove(key);
      log.d(
          'URL expirada removida del cache: producto ${cachedUrl?.productId}');
    }

    if (expiredKeys.isNotEmpty) {
      log.i('Cache limpiado: ${expiredKeys.length} URLs expiradas removidas');
    }
  }

  /// Limpia todo el cache (útil para logout o cambios de configuración)
  void clearAll() {
    final count = _urlCache.length;
    _urlCache.clear();
    log.i('Cache completamente limpiado: $count URLs removidas');
  }

  /// Obtiene estadísticas del cache para debugging
  Map<String, dynamic> getCacheStats() {
    int validCount = 0;
    int expiredCount = 0;

    _urlCache.forEach((key, cachedUrl) {
      if (cachedUrl.isExpired()) {
        expiredCount++;
      } else {
        validCount++;
      }
    });

    return {
      'total_cached_urls': _urlCache.length,
      'valid_urls': validCount,
      'expired_urls': expiredCount,
      'cache_hit_potential': _urlCache.isNotEmpty
          ? (validCount / _urlCache.length * 100).toStringAsFixed(1)
          : '0.0',
      'last_cleanup': DateTime.now().toIso8601String(),
    };
  }

  /// Inicia el timer de limpieza automática
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      cleanExpiredUrls();
    });
    log.d('Timer de limpieza iniciado, ejecutándose cada $_cleanupInterval');
  }

  /// Detiene el timer de limpieza (útil para testing o shutdown)
  void stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    log.d('Timer de limpieza detenido');
  }

  /// Cleanup recursos al destruir el servicio
  void dispose() {
    stopCleanupTimer();
    clearAll();
    log.d('Servicio de cache disposed');
  }
}

/// Clase interna para representar una URL cacheada con su expiración
class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  final int productId;

  _CachedUrl({
    required this.url,
    required this.expiresAt,
    required this.productId,
  });

  /// Verifica si la URL ha expirado
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Tiempo restante antes de expirar
  Duration timeUntilExpiry() {
    final now = DateTime.now();
    return expiresAt.isAfter(now) ? expiresAt.difference(now) : Duration.zero;
  }

  @override
  String toString() {
    return '_CachedUrl(productId: $productId, expiresAt: $expiresAt, timeLeft: ${timeUntilExpiry()})';
  }
}
