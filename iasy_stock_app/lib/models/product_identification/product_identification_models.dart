import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_identification_models.freezed.dart';
part 'product_identification_models.g.dart';

/// Modelo para solicitud de identificación o creación de producto
@freezed
class IdentifyOrCreateProductRequest with _$IdentifyOrCreateProductRequest {
  const factory IdentifyOrCreateProductRequest({
    required String imageBase64,
    @Default('jpeg') String imageFormat,
    String? name,
    String? description,
    int? categoryId,
    int? stockQuantity,
    String? expirationDate,
    @Default('MANUAL') String source,
  }) = _IdentifyOrCreateProductRequest;

  factory IdentifyOrCreateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$IdentifyOrCreateProductRequestFromJson(json);
}

/// Modelo para resultado de identificación de producto
@freezed
class ProductIdentificationResult with _$ProductIdentificationResult {
  const factory ProductIdentificationResult({
    required String status,
    required ProductSummary product,
    required bool isExisting,
    required double confidence,
    String? matchType,
    double? similarity,
    required bool requiresValidation,
    required String details,
    @Default([]) List<IdentificationMatch> alternativeMatches,
    required int processingTimeMs,
    @Default({}) Map<String, dynamic> metadata,
  }) = _ProductIdentificationResult;

  factory ProductIdentificationResult.fromJson(Map<String, dynamic> json) =>
      _$ProductIdentificationResultFromJson(json);
}

/// Modelo para un match de identificación individual
@freezed
class IdentificationMatch with _$IdentificationMatch {
  const factory IdentificationMatch({
    required ProductSummary product,
    required double confidence,
    required String matchType,
    required String details,
    double? similarity,
    @Default({}) Map<String, dynamic> metadata,
  }) = _IdentificationMatch;

  factory IdentificationMatch.fromJson(Map<String, dynamic> json) =>
      _$IdentificationMatchFromJson(json);
}

/// Modelo resumido de producto
@freezed
class ProductSummary with _$ProductSummary {
  const factory ProductSummary({
    required int id,
    required String name,
    String? description,
    String? imageUrl,
    required int categoryId,
    int? stockQuantity,
    String? barcodeData,
    String? brandName,
    String? modelNumber,
    String? inferredCategory,
    double? recognitionAccuracy,
    DateTime? createdAt,
  }) = _ProductSummary;

  factory ProductSummary.fromJson(Map<String, dynamic> json) =>
      _$ProductSummaryFromJson(json);
}

/// Modelo para request de validación
@freezed
class ValidateIdentificationRequest with _$ValidateIdentificationRequest {
  const factory ValidateIdentificationRequest({
    required String imageHash,
    int? suggestedProductId,
    int? actualProductId,
    required double confidenceScore,
    required String matchType,
    required bool wasCorrect,
    required int userId,
    String? notes,
    @Default('MANUAL') String source,
    int? relatedSaleId,
    int? relatedStockId,
  }) = _ValidateIdentificationRequest;

  factory ValidateIdentificationRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidateIdentificationRequestFromJson(json);
}

/// Modelo para validación guardada
@freezed
class ProductIdentificationValidation with _$ProductIdentificationValidation {
  const factory ProductIdentificationValidation({
    int? validationId,
    required String imageHash,
    String? imageUrl,
    int? suggestedProductId,
    int? actualProductId,
    required double confidenceScore,
    required String matchType,
    double? similarityScore,
    required bool wasCorrect,
    required String correctionType,
    required int validatedBy,
    required DateTime validatedAt,
    String? feedbackNotes,
    required String validationSource,
    int? relatedSaleId,
    int? relatedStockId,
  }) = _ProductIdentificationValidation;

  factory ProductIdentificationValidation.fromJson(Map<String, dynamic> json) =>
      _$ProductIdentificationValidationFromJson(json);
}

/// Modelo para configuración de umbrales
@freezed
class IdentificationThresholdConfig with _$IdentificationThresholdConfig {
  const factory IdentificationThresholdConfig({
    int? configId,
    required double barcodeMinConfidence,
    required double hashMinConfidence,
    required double brandModelMinConfidence,
    required double vectorSimilarityMinConfidence,
    required double tagCategoryMinConfidence,
    required double clipSimilarityMinConfidence,
    required double autoApproveThreshold,
    required double manualValidationThreshold,
    required int totalIdentifications,
    required int correctIdentifications,
    required int falsePositives,
    required int falseNegatives,
    double? accuracy,
    DateTime? lastTrainingAt,
    required String modelVersion,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _IdentificationThresholdConfig;

  factory IdentificationThresholdConfig.fromJson(Map<String, dynamic> json) =>
      _$IdentificationThresholdConfigFromJson(json);
}

/// Modelo para métricas de precisión
@freezed
class AccuracyMetrics with _$AccuracyMetrics {
  const factory AccuracyMetrics({
    required int totalValidations,
    required int correctValidations,
    required int falsePositives,
    required int falseNegatives,
    required double accuracy,
    required String accuracyPercentage,
  }) = _AccuracyMetrics;

  factory AccuracyMetrics.fromJson(Map<String, dynamic> json) =>
      _$AccuracyMetricsFromJson(json);
}

/// Estados de identificación
enum IdentificationStatus {
  @JsonValue('IDENTIFIED')
  identified,
  @JsonValue('PARTIAL_MATCH')
  partialMatch,
  @JsonValue('NEW_PRODUCT_CREATED')
  newProductCreated,
  @JsonValue('MULTIPLE_MATCHES')
  multipleMatches,
  @JsonValue('ERROR')
  error,
}

/// Tipos de match
enum MatchType {
  @JsonValue('EXACT_BARCODE')
  exactBarcode,
  @JsonValue('EXACT_HASH')
  exactHash,
  @JsonValue('BRAND_MODEL')
  brandModel,
  @JsonValue('CLIP_SIMILARITY')
  clipSimilarity,
  @JsonValue('VECTOR_SIMILARITY')
  vectorSimilarity,
  @JsonValue('TAG_CATEGORY')
  tagCategory,
  @JsonValue('MULTI_FACTOR')
  multiFactor,
}

/// Tipos de corrección
enum CorrectionType {
  @JsonValue('CORRECT')
  correct,
  @JsonValue('FALSE_POSITIVE')
  falsePositive,
  @JsonValue('FALSE_NEGATIVE')
  falseNegative,
  @JsonValue('IMPROVED')
  improved,
}

/// Fuentes de validación
enum ValidationSource {
  @JsonValue('SALE')
  sale,
  @JsonValue('STOCK')
  stock,
  @JsonValue('MANUAL')
  manual,
}

// ============================================================================
// MODELOS PARA DETECCIÓN MÚLTIPLE DE PRODUCTOS
// ============================================================================

/// Modelo para solicitud de detección múltiple de productos
@freezed
class MultipleProductDetectionRequest with _$MultipleProductDetectionRequest {
  const factory MultipleProductDetectionRequest({
    required String imageBase64,
    @Default('jpeg') String imageFormat,
    @Default('MOBILE_APP') String source,
    int? userId,
    @Default(true) bool groupByProduct,
    double? minConfidence,
  }) = _MultipleProductDetectionRequest;

  factory MultipleProductDetectionRequest.fromJson(Map<String, dynamic> json) =>
      _$MultipleProductDetectionRequestFromJson(json);
}

/// Modelo para bounding box (coordenadas normalizadas 0-1)
@freezed
class BoundingBox with _$BoundingBox {
  const factory BoundingBox({
    required double x, // Centro X normalizado (0-1)
    required double y, // Centro Y normalizado (0-1)
    required double width, // Ancho normalizado (0-1)
    required double height, // Alto normalizado (0-1)
  }) = _BoundingBox;

  factory BoundingBox.fromJson(Map<String, dynamic> json) =>
      _$BoundingBoxFromJson(json);
}

/// Modelo para un producto detectado e identificado
@freezed
class DetectedProductMatch with _$DetectedProductMatch {
  const factory DetectedProductMatch({
    required ProductSummary product,
    required BoundingBox boundingBox,
    required double detectionConfidence, // Confianza de YOLO
    required double identificationConfidence, // Confianza de identificación
    required double combinedConfidence, // Confianza combinada
    required String matchType,
    double? similarity,
    @Default([]) List<IdentificationMatch> alternativeMatches,
    required int objectIndex,
  }) = _DetectedProductMatch;

  factory DetectedProductMatch.fromJson(Map<String, dynamic> json) =>
      _$DetectedProductMatchFromJson(json);
}

/// Modelo para grupo de productos del mismo tipo
@freezed
class DetectedProductGroup with _$DetectedProductGroup {
  const factory DetectedProductGroup({
    required ProductSummary product,
    required int quantity,
    required double averageConfidence,
    required List<DetectedProductMatch> detections,
    @Default(true) bool isConfirmed,
  }) = _DetectedProductGroup;

  factory DetectedProductGroup.fromJson(Map<String, dynamic> json) =>
      _$DetectedProductGroupFromJson(json);
}

/// Modelo para resultado de detección múltiple
@freezed
class MultipleProductDetectionResult with _$MultipleProductDetectionResult {
  const factory MultipleProductDetectionResult({
    required String status,
    required List<DetectedProductGroup> productGroups,
    required int totalDetections,
    required int uniqueProducts,
    required bool requiresValidation,
    required int processingTimeMs,
    @Default({}) Map<String, dynamic> metadata,
  }) = _MultipleProductDetectionResult;

  factory MultipleProductDetectionResult.fromJson(Map<String, dynamic> json) =>
      _$MultipleProductDetectionResultFromJson(json);
}
