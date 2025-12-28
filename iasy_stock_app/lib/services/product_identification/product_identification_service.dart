import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/product_identification/product_identification_models.dart';

final Logger _identificationLog = Logger();

/// Servicio para identificación inteligente de productos
///
/// Comunicación con backend para:
/// - Identificar o crear productos desde imágenes
/// - Validar identificaciones (feedback loop)
/// - Consultar configuración de umbrales ML
/// - Obtener métricas de precisión
class ProductIdentificationService {
  final Dio _dio;

  ProductIdentificationService({
    required Dio dio,
  }) : _dio = dio;

  /// Identifica o crea un producto a partir de una imagen
  ///
  /// Flujo:
  /// 1. Convierte imagen a base64
  /// 2. Envía al backend con metadatos
  /// 3. Backend procesa con OpenAI + CLIP + búsquedas multi-criterio
  /// 4. Retorna resultado: producto identificado o recién creado
  ///
  /// [imageBytes] - Bytes de la imagen capturada (compatible con web y móvil)
  /// [imageName] - Nombre del archivo de imagen (para detectar formato)
  /// [name] - Nombre opcional del producto (si no se identifica)
  /// [description] - Descripción opcional
  /// [categoryId] - ID de categoría
  /// [stockQuantity] - Cantidad de stock inicial
  /// [source] - Fuente de la identificación (SALE, STOCK, MANUAL)
  Future<ProductIdentificationResult> identifyOrCreateProduct({
    required Uint8List imageBytes,
    String imageName = 'image.jpg',
    String? name,
    String? description,
    int? categoryId,
    int? stockQuantity,
    String? expirationDate,
    String source = 'MANUAL',
  }) async {
    _identificationLog.d(
      'Identificando producto desde imagen: $imageName, source: $source',
    );

    try {
      // Convertir imagen a base64
      final imageBase64 = base64Encode(imageBytes);

      // Detectar formato de imagen
      final extension = imageName.split('.').last.toLowerCase();
      final imageFormat = _mapImageFormat(extension);

      // Preparar request
      final requestData = IdentifyOrCreateProductRequest(
        imageBase64: imageBase64,
        imageFormat: imageFormat,
        name: name,
        description: description,
        categoryId: categoryId,
        stockQuantity: stockQuantity,
        expirationDate: expirationDate,
        source: source,
      ).toJson();

      _identificationLog.d(
        'Enviando imagen de ${imageBytes.length} bytes, formato: $imageFormat',
      );

      // Llamar al backend
      final response = await _dio.post(
        '/api/v1/product-identification/identify-or-create',
        data: requestData,
      );

      // Parsear response
      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final resultData = apiResponse['data'];
        final result = ProductIdentificationResult.fromJson(resultData);

        _identificationLog.i(
          '✅ Identificación completada: status=${result.status}, '
          'producto=${result.product.name}, '
          'confianza=${result.confidence}, '
          'tiempo=${result.processingTimeMs}ms',
        );

        return result;
      } else {
        throw Exception(
            apiResponse['error'] ?? 'Error desconocido en identificación');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Identificar o crear producto');
      rethrow;
    } catch (e) {
      _identificationLog.e('Error inesperado: $e');
      rethrow;
    }
  }

  /// Valida una identificación de producto (feedback loop para ML)
  ///
  /// Usado cuando el usuario confirma/corrige una identificación.
  /// El backend usa estas validaciones para reentrenar el modelo automáticamente.
  ///
  /// [imageHash] - Hash de la imagen original
  /// [suggestedProductId] - ID del producto sugerido por el sistema
  /// [actualProductId] - ID del producto real (puede ser diferente si hubo error)
  /// [confidenceScore] - Score de confianza de la identificación original
  /// [matchType] - Tipo de match que se usó
  /// [wasCorrect] - Si la identificación fue correcta
  /// [userId] - ID del usuario que valida
  /// [notes] - Notas opcionales de feedback
  /// [source] - Fuente de la validación (SALE, STOCK, MANUAL)
  Future<ProductIdentificationValidation> validateIdentification({
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
    _identificationLog.d(
      'Validando identificación: wasCorrect=$wasCorrect, imageHash=${imageHash.substring(0, 16)}...',
    );

    try {
      final requestData = ValidateIdentificationRequest(
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
      ).toJson();

      final response = await _dio.post(
        '/api/v1/product-identification/validate',
        data: requestData,
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final validationData = apiResponse['data'];
        final validation =
            ProductIdentificationValidation.fromJson(validationData);

        _identificationLog.i(
          '✅ Validación guardada: ID=${validation.validationId}, correctionType=${validation.correctionType}',
        );

        return validation;
      } else {
        throw Exception(apiResponse['error'] ?? 'Error guardando validación');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Validar identificación');
      rethrow;
    }
  }

  /// Obtiene validaciones recientes del sistema
  ///
  /// Útil para mostrar historial de validaciones en panel de administración
  Future<List<ProductIdentificationValidation>> getRecentValidations({
    int limit = 50,
  }) async {
    _identificationLog.d('Obteniendo últimas $limit validaciones');

    try {
      final response = await _dio.get(
        '/api/v1/product-identification/validations/recent',
        queryParameters: {'limit': limit},
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final validationsData = apiResponse['data'] as List;
        final validations = validationsData
            .map((json) => ProductIdentificationValidation.fromJson(json))
            .toList();

        _identificationLog.i('✅ ${validations.length} validaciones obtenidas');

        return validations;
      } else {
        throw Exception(
            apiResponse['error'] ?? 'Error obteniendo validaciones');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener validaciones recientes');
      rethrow;
    }
  }

  /// Obtiene la configuración activa de umbrales ML
  ///
  /// Muestra los umbrales actuales para cada tipo de match y métricas del modelo
  Future<IdentificationThresholdConfig> getActiveConfig() async {
    _identificationLog.d('Obteniendo configuración activa');

    try {
      final response = await _dio.get(
        '/api/v1/product-identification/config/active',
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final configData = apiResponse['data'];
        final config = IdentificationThresholdConfig.fromJson(configData);

        _identificationLog.i(
          '✅ Config activa: versión ${config.modelVersion}, accuracy ${config.accuracy}',
        );

        return config;
      } else {
        throw Exception(
            apiResponse['error'] ?? 'Error obteniendo configuración');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener configuración activa');
      rethrow;
    }
  }

  /// Obtiene métricas de precisión del sistema de identificación
  ///
  /// Incluye: total de validaciones, correctas, false positives, false negatives, accuracy
  Future<AccuracyMetrics> getMetrics() async {
    _identificationLog.d('Obteniendo métricas de precisión');

    try {
      final response = await _dio.get(
        '/api/v1/product-identification/metrics',
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final metricsData = apiResponse['data'];
        final metrics = AccuracyMetrics.fromJson(metricsData);

        _identificationLog.i(
          '✅ Métricas: total=${metrics.totalValidations}, accuracy=${metrics.accuracyPercentage}',
        );

        return metrics;
      } else {
        throw Exception(apiResponse['error'] ?? 'Error obteniendo métricas');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener métricas');
      rethrow;
    }
  }

  /// Trigger manual de reentrenamiento del modelo ML
  ///
  /// Generalmente se ejecuta automáticamente cada 100 validaciones,
  /// pero puede ejecutarse manualmente desde panel de admin
  Future<void> triggerRetraining() async {
    _identificationLog.d('Triggereando reentrenamiento manual');

    try {
      final response = await _dio.post(
        '/api/v1/product-identification/retrain',
      );

      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        _identificationLog.i('✅ Reentrenamiento completado exitosamente');
      } else {
        throw Exception(apiResponse['error'] ?? 'Error en reentrenamiento');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Trigger reentrenamiento');
      rethrow;
    }
  }

  /// Detecta e identifica múltiples productos en una sola imagen
  ///
  /// Flujo:
  /// 1. Convierte imagen a base64
  /// 2. Backend usa YOLO para detectar objetos
  /// 3. Para cada objeto detectado, usa OpenAI + CLIP para identificar
  /// 4. Agrupa productos por ID y calcula cantidades
  /// 5. Retorna lista de productos con cantidades y bounding boxes
  ///
  /// [imageBytes] - Bytes de la imagen con múltiples productos (compatible con web y móvil)
  /// [imageName] - Nombre del archivo de imagen (para detectar formato)
  /// [source] - Fuente de la identificación (default: MOBILE_APP)
  /// [userId] - ID del usuario (opcional)
  /// [groupByProduct] - Agrupar productos del mismo tipo (default: true)
  /// [minConfidence] - Confianza mínima para aceptar productos (opcional)
  Future<MultipleProductDetectionResult> identifyMultipleProducts({
    required Uint8List imageBytes,
    String imageName = 'image.jpg',
    String source = 'MOBILE_APP',
    int? userId,
    bool groupByProduct = true,
    double? minConfidence,
  }) async {
    _identificationLog.d(
      'Detectando múltiples productos en imagen: $imageName',
    );

    try {
      // Convertir imagen a base64
      final imageBase64 = base64Encode(imageBytes);

      // Detectar formato de imagen
      final extension = imageName.split('.').last.toLowerCase();
      final imageFormat = _mapImageFormat(extension);

      // Preparar request
      final requestData = MultipleProductDetectionRequest(
        imageBase64: imageBase64,
        imageFormat: imageFormat,
        source: source,
        userId: userId,
        groupByProduct: groupByProduct,
        minConfidence: minConfidence,
      ).toJson();

      _identificationLog.d(
        'Enviando imagen de ${imageBytes.length} bytes para detección múltiple',
      );

      // Llamar al backend
      final response = await _dio.post(
        '/api/v1/product-identification/identify-multiple',
        data: requestData,
      );

      // Parsear response
      final apiResponse = response.data;

      if (apiResponse['success'] == true) {
        final resultData = apiResponse['data'];
        final result = MultipleProductDetectionResult.fromJson(resultData);

        _identificationLog.i(
          '✅ Detección múltiple completada: '
          'totalDetections=${result.totalDetections}, '
          'uniqueProducts=${result.uniqueProducts}, '
          'tiempo=${result.processingTimeMs}ms',
        );

        // Log de productos detectados
        for (final group in result.productGroups) {
          _identificationLog.d(
            '   📦 ${group.product.name}: cantidad=${group.quantity}, '
            'confianza=${(group.averageConfidence * 100).toStringAsFixed(1)}%, '
            'confirmado=${group.isConfirmed}',
          );
        }

        return result;
      } else {
        throw Exception(
            apiResponse['error'] ?? 'Error desconocido en detección múltiple');
      }
    } on DioException catch (e) {
      _logDioError(e, context: 'Detectar múltiples productos');
      rethrow;
    } catch (e) {
      _identificationLog.e('Error inesperado: $e');
      rethrow;
    }
  }

  /// Mapea extensión de archivo a formato de imagen
  String _mapImageFormat(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      case 'bmp':
        return 'bmp';
      default:
        return 'jpeg';
    }
  }

  /// Log de errores Dio
  void _logDioError(DioException e, {required String context}) {
    _identificationLog.e('❌ Error en $context: ${e.message}');
    if (e.response != null) {
      _identificationLog.e('Respuesta del servidor: ${e.response?.data}');
    }
  }
}
