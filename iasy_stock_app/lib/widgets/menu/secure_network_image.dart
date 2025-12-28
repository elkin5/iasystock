import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../config/get_it_config.dart';
import '../../services/menu/product_service.dart';
import '../../services/secure_image_cache_service.dart';
import '../../theme/app_colors.dart';

/// Widget inteligente para manejar imágenes de red con URLs firmadas temporales
///
/// Características:
/// - Renovación automática de URLs expiradas
/// - Retry logic inteligente
/// - Estados de carga y error mejorados
/// - Compatible con cache de Flutter
///
/// Uso:
/// ```dart
/// SecureNetworkImage(
///   imageUrl: product.imageUrl,
///   productId: product.id,
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
class SecureNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final int? productId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration retryDelay;
  final int maxRetries;

  const SecureNetworkImage({
    super.key,
    required this.imageUrl,
    required this.productId,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.retryDelay = const Duration(seconds: 1),
    this.maxRetries = 2,
  });

  @override
  State<SecureNetworkImage> createState() => _SecureNetworkImageState();
}

final Logger log = Logger();

class _SecureNetworkImageState extends State<SecureNetworkImage> {
  // Servicio de cache para URLs firmadas
  final _cacheService = SecureImageCacheService();

  String? _currentImageUrl;
  bool _isLoading = false;
  bool _hasError = false;
  int _retryCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeImageUrl();
  }

  @override
  void didUpdateWidget(SecureNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la URL o productId cambió, reinicializar
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.productId != widget.productId) {
      _initializeImageUrl();
    }
  }

  /// Inicializa la URL de imagen, priorizando cache sobre la URL original
  void _initializeImageUrl() {
    // Intentar obtener URL del cache primero si tenemos productId
    if (widget.productId != null) {
      final cachedUrl = _cacheService.getCachedImageUrl(widget.productId!);
      final fallbackUrl =
          _isLoopbackUrl(widget.imageUrl) ? null : widget.imageUrl;

      setState(() {
        _currentImageUrl = cachedUrl ?? fallbackUrl;
        _hasError = false;
        _retryCount = 0;
        _errorMessage = null;
      });

      if (cachedUrl != null) {
        log.d("Usando URL del cache para producto ${widget.productId}");
      } else {
        log.d(
            "No hay URL en cache, usando URL original para producto ${widget.productId}");
        if (fallbackUrl == null) {
          log.d(
              "URL original omitida por apuntar a loopback, solicitando renovación inmediata");
        }
        if (widget.productId != null) {
          // Renovar inmediatamente para evitar intentos fallidos contra localhost/loopback
          _refreshImageUrl();
        }
      }
    } else {
      setState(() {
        _currentImageUrl = widget.imageUrl;
        _hasError = false;
        _retryCount = 0;
        _errorMessage = null;
      });
    }
  }

  /// Intenta renovar la URL de imagen usando el servicio del backend
  Future<void> _refreshImageUrl() async {
    if (widget.productId == null) {
      log.w("No se puede renovar URL: productId es null");
      return;
    }

    if (!mounted) {
      log.d("_refreshImageUrl abortado: widget desmontado");
      return;
    }

    if (_isLoading) {
      log.d(
          "Renovación de URL ya en progreso para producto ${widget.productId}");
      return;
    }

    // Verificar si ya tenemos una URL válida en cache
    final cachedUrl = _cacheService.getCachedImageUrl(widget.productId!);
    if (cachedUrl != null) {
      log.d(
          "URL válida encontrada en cache para producto ${widget.productId}, no se requiere renovación");
      if (!mounted) {
        return;
      }
      setState(() {
        _currentImageUrl = cachedUrl;
        _hasError = false;
        _retryCount = 0;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Invalidar cache anterior si existe
      _cacheService.invalidateCache(widget.productId!);

      // Obtener servicio de GetIt
      final productService = getIt<ProductService>();

      log.d("Renovando URL para producto ${widget.productId}");

      final newUrl = await productService.refreshImageUrl(widget.productId!);

      // Guardar nueva URL en cache
      _cacheService.cacheImageUrl(widget.productId!, newUrl);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentImageUrl = newUrl;
        _isLoading = false;
        _retryCount = 0;
        _errorMessage = null;
      });

      log.i(
          "URL renovada y cacheada exitosamente para producto ${widget.productId}");
      if (_isLoopbackUrl(newUrl)) {
        log.w(
            "La URL renovada para producto ${widget.productId} apunta a loopback; verifique la configuración del backend o DEV_HOST");
      }
    } catch (e) {
      log.e("Error al renovar URL: $e");
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Error al renovar imagen: ${e.toString()}";
      });
    }
  }

  /// Maneja errores de carga de imagen con lógica de reintento inteligente
  Widget _handleImageError(
      BuildContext context, Object error, StackTrace? stackTrace) {
    log.w("Error cargando imagen: $error");

    // Si el error parece ser una URL expirada, invalidar cache
    if (_isLikelyExpiredUrl(error) && widget.productId != null) {
      _cacheService.invalidateCache(widget.productId!);
      log.d(
          "Cache invalidado para producto ${widget.productId} debido a error de URL");
    }

    // Solo intentar renovar si:
    // 1. Tenemos productId
    // 2. No hemos excedido el límite de reintentos
    // 3. El error podría ser una URL expirada
    final canRetry = widget.productId != null &&
        _retryCount < widget.maxRetries &&
        _isLikelyExpiredUrl(error);

    if (canRetry && !_isLoading) {
      // Incrementar contador y reintentar después de un delay
      _retryCount++;

      log.d(
          "Reintentando carga de imagen (intento $_retryCount/${widget.maxRetries})");

      Future.delayed(widget.retryDelay, () {
        if (mounted) {
          _refreshImageUrl();
        }
      });

      // Mostrar indicador de carga mientras reintenta
      return _buildLoadingWidget();
    }

    // Si no se puede reintentar, mostrar widget de error
    return _buildErrorWidget();
  }

  /// Determina si el error podría ser una URL expirada
  bool _isLikelyExpiredUrl(Object error) {
    final errorString = error.toString().toLowerCase();

    // Patrones comunes de URLs expiradas o acceso denegado
    final expiredPatterns = [
      '403',
      'forbidden',
      'access denied',
      '404',
      'not found',
      'expired',
      'invalid signature',
      'network image failed',
      'http error',
      'socketexception',
      'connection refused',
    ];

    return expiredPatterns.any((pattern) => errorString.contains(pattern));
  }

  bool _isLoopbackUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    final host = uri.host.toLowerCase();
    // Incluir 10.0.2.2 que es el alias de localhost desde el emulador Android
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '10.0.2.2';
  }

  /// Transforma una URL para que sea compatible con la plataforma actual.
  /// En web, convierte 10.0.2.2 a localhost.
  String _transformUrlForPlatform(String url) {
    if (!kIsWeb) return url;

    // En web, reemplazar 10.0.2.2 por localhost
    if (url.contains('10.0.2.2')) {
      final transformed = url.replaceAll('10.0.2.2', 'localhost');
      log.d('URL transformada para web: $url -> $transformed');
      return transformed;
    }
    return url;
  }

  /// Calcula un ancho seguro basado en widget.width y constraints disponibles
  double _getSafeWidth(double availableWidth) {
    if (widget.width == null) return 200.0;
    if (widget.width == double.infinity) return availableWidth;
    if (!widget.width!.isFinite) return 200.0;
    return widget.width!;
  }

  /// Calcula un alto seguro basado en widget.height y constraints disponibles
  double _getSafeHeight(double availableHeight) {
    if (widget.height == null) return 200.0;
    if (widget.height == double.infinity) return availableHeight;
    if (!widget.height!.isFinite) return 200.0;
    return widget.height!;
  }

  /// Widget de carga durante renovación de URL
  Widget _buildLoadingWidget() {
    if (widget.placeholder != null) return widget.placeholder!;

    // Obtener constraints disponibles del contexto
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular dimensiones seguras basadas en constraints disponibles
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;

        final width = _getSafeWidth(availableWidth);
        final height = _getSafeHeight(availableHeight);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceEmphasis(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 8),
                Text(
                  "Cargando imagen...",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget de error cuando no se puede cargar la imagen
  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) return widget.errorWidget!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;

        final width = _getSafeWidth(availableWidth);
        final height = _getSafeHeight(availableHeight);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceEmphasis(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder(context)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: AppColors.iconMuted(context),
                ),
                const SizedBox(height: 8),
                Text(
                  "No se pudo cargar\nla imagen",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted(context),
                  ),
                ),
                if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Toca para reintentar",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.info(context),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget cuando no hay imagen disponible
  Widget _buildNoImageWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;

        final width = _getSafeWidth(availableWidth);
        final height = _getSafeHeight(availableHeight);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceEmphasis(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder(context)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 40,
                  color: AppColors.iconMuted(context),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sin imagen\ndisponible",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay URL de imagen, mostrar placeholder
    if (_currentImageUrl == null || _currentImageUrl!.isEmpty) {
      return _buildNoImageWidget();
    }

    // Si está cargando una nueva URL, mostrar indicador
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Si hay error persistente, mostrar widget de error con opción de reintento manual
    if (_hasError) {
      return GestureDetector(
        onTap: () {
          if (widget.productId != null) {
            setState(() {
              _retryCount = 0;
              _hasError = false;
            });
            _refreshImageUrl();
          }
        },
        child: _buildErrorWidget(),
      );
    }

    // Cargar imagen normalmente con manejo de errores inteligente
    // Transformar URL para compatibilidad entre plataformas (web vs móvil)
    final urlToLoad = _transformUrlForPlatform(_currentImageUrl!);

    return Image.network(
      urlToLoad,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: _handleImageError,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        // Usar la imagen actual con overlay de progreso para evitar problemas de constraints
        return Stack(
          alignment: Alignment.center,
          children: [
            // Imagen parcialmente cargada (si existe) o placeholder
            child,
            // Overlay con indicador de progreso
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  backgroundColor: Colors.white24,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              ),
            ),
          ],
        );
      },
      // Headers para mejorar cache y compatibilidad
      headers: const {
        'User-Agent': 'IasyStock Flutter App',
      },
    );
  }
}
