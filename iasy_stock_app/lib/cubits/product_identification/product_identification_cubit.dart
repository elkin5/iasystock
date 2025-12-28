import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../services/product_identification/product_identification_service.dart';
import 'product_identification_state.dart';

final Logger _cubitLog = Logger();

/// Cubit para manejar el estado de identificación inteligente de productos
///
/// Funcionalidades:
/// - Identificar o crear producto desde imagen
/// - Validar identificaciones (feedback loop ML)
/// - Consultar configuración y métricas del sistema
class ProductIdentificationCubit extends Cubit<ProductIdentificationState> {
  final ProductIdentificationService _service;

  ProductIdentificationCubit({
    required ProductIdentificationService service,
  })  : _service = service,
        super(ProductIdentificationInitial());

  /// Identifica o crea un producto desde una imagen
  ///
  /// Este es el método principal del flujo de identificación.
  /// Envía la imagen al backend que procesa con OpenAI + CLIP + búsquedas multi-criterio.
  ///
  /// [imageBytes] - Bytes de la imagen capturada (compatible con web y móvil)
  /// [imageName] - Nombre del archivo de imagen (para detectar formato)
  /// [name] - Nombre opcional (usado si no se identifica el producto)
  /// [description] - Descripción opcional
  /// [categoryId] - ID de categoría
  /// [stockQuantity] - Cantidad de stock inicial
  /// [source] - Fuente de la identificación ('SALE', 'STOCK', 'MANUAL')
  Future<void> identifyOrCreateProduct({
    required Uint8List imageBytes,
    String imageName = 'image.jpg',
    String? name,
    String? description,
    int? categoryId,
    int? stockQuantity,
    String? expirationDate,
    String source = 'MANUAL',
  }) async {
    _cubitLog.d(
      'Iniciando identificación de producto desde imagen: $imageName',
    );

    emit(const ProductIdentificationProcessing(
      message: 'Analizando imagen con IA...',
    ));

    try {
      final result = await _service.identifyOrCreateProduct(
        imageBytes: imageBytes,
        imageName: imageName,
        name: name,
        description: description,
        categoryId: categoryId,
        stockQuantity: stockQuantity,
        expirationDate: expirationDate,
        source: source,
      );

      _cubitLog.i(
        '✅ Identificación completada: status=${result.status}, '
        'producto=${result.product.name}, '
        'confianza=${result.confidence}',
      );

      emit(ProductIdentificationSuccess(result: result));
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error en identificación: $e',
          error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(ProductIdentificationError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Valida una identificación de producto
  ///
  /// Este método se usa cuando el usuario confirma o corrige una identificación.
  /// La validación se envía al backend para el feedback loop de ML.
  ///
  /// [imageHash] - Hash de la imagen original
  /// [suggestedProductId] - ID del producto que el sistema sugirió
  /// [actualProductId] - ID del producto real (puede ser diferente si hubo error)
  /// [confidenceScore] - Score de confianza original
  /// [matchType] - Tipo de match usado
  /// [wasCorrect] - Si la identificación fue correcta
  /// [userId] - ID del usuario que valida
  /// [notes] - Notas opcionales de feedback
  /// [source] - Fuente de la validación
  Future<void> validateIdentification({
    required String imageHash,
    int? suggestedProductId,
    int? actualProductId,
    required double confidenceScore,
    required String matchType,
    required bool wasCorrect,
    required int userId,
    String? notes,
    String source = 'MANUAL',
    int? relatedSaleId,
    int? relatedStockId,
  }) async {
    _cubitLog.d('Validando identificación: wasCorrect=$wasCorrect');

    emit(const ProductValidationProcessing(
      message: 'Guardando validación...',
    ));

    try {
      final validation = await _service.validateIdentification(
        imageHash: imageHash,
        suggestedProductId: suggestedProductId,
        actualProductId: actualProductId,
        confidenceScore: confidenceScore,
        matchType: matchType,
        wasCorrect: wasCorrect,
        userId: userId,
        notes: notes,
        source: source,
        relatedSaleId: relatedSaleId,
        relatedStockId: relatedStockId,
      );

      _cubitLog.i(
        '✅ Validación guardada: ID=${validation.validationId}, '
        'correctionType=${validation.correctionType}',
      );

      emit(ProductValidationSuccess(validation: validation));
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error guardando validación: $e',
          error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(ProductIdentificationError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Obtiene la configuración activa de umbrales ML
  Future<void> getActiveConfig() async {
    _cubitLog.d('Obteniendo configuración activa');

    emit(ProductIdentificationConfigLoading());

    try {
      final config = await _service.getActiveConfig();

      _cubitLog.i('✅ Config cargada: versión ${config.modelVersion}');

      emit(ProductIdentificationConfigLoaded(config: config));
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error obteniendo config: $e',
          error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(ProductIdentificationError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Obtiene métricas de precisión del sistema
  Future<void> getMetrics() async {
    _cubitLog.d('Obteniendo métricas de precisión');

    emit(ProductIdentificationConfigLoading());

    try {
      final metrics = await _service.getMetrics();

      _cubitLog
          .i('✅ Métricas cargadas: accuracy=${metrics.accuracyPercentage}');

      emit(ProductIdentificationMetricsLoaded(metrics: metrics));
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error obteniendo métricas: $e',
          error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(ProductIdentificationError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Trigger manual de reentrenamiento del modelo
  Future<void> triggerRetraining() async {
    _cubitLog.d('Triggereando reentrenamiento manual');

    emit(const ProductIdentificationProcessing(
      message: 'Reentrenando modelo de ML...',
    ));

    try {
      await _service.triggerRetraining();

      _cubitLog.i('✅ Reentrenamiento completado');

      // Recargar configuración actualizada
      await getActiveConfig();
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error en reentrenamiento: $e',
          error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(ProductIdentificationError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Resetea el estado a inicial
  void reset() {
    _cubitLog.d('Reseteando estado del cubit');
    emit(ProductIdentificationInitial());
  }

  /// Extrae mensaje de error legible desde excepciones
  String _extractErrorMessage(dynamic error) {
    if (error == null) return 'Error desconocido';

    final errorString = error.toString();

    // Intentar extraer mensaje de error más limpio
    if (errorString.contains('Exception:')) {
      return errorString.split('Exception:').last.trim();
    }

    if (errorString.contains('Error:')) {
      return errorString.split('Error:').last.trim();
    }

    // Mensajes de error comunes
    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    }

    if (errorString.contains('TimeoutException')) {
      return 'La operación tardó demasiado. Intenta nuevamente.';
    }

    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'No autorizado. Inicia sesión nuevamente.';
    }

    if (errorString.contains('404')) {
      return 'Recurso no encontrado.';
    }

    if (errorString.contains('500')) {
      return 'Error del servidor. Intenta más tarde.';
    }

    // Si no se encuentra un patrón conocido, retornar el error completo
    return errorString.length > 200
        ? '${errorString.substring(0, 200)}...'
        : errorString;
  }
}
