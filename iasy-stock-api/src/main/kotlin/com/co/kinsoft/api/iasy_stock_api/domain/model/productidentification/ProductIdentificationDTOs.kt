package com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import java.math.BigDecimal
import java.time.LocalDateTime

/**
 * DTOs para API REST de Product Identification
 */

// ============================================================================
// Request DTOs
// ============================================================================

/**
 * Request para identificar o crear producto desde imagen
 */
data class IdentifyOrCreateProductRequestDTO(
    val imageBase64: String,  // Imagen en base64
    val imageFormat: String = "jpeg",
    val name: String? = null,
    val description: String? = null,
    val categoryId: Long? = null,
    val stockQuantity: Int? = null,
    val expirationDate: String? = null,  // ISO-8601 format
    val source: String = "MANUAL"  // SALE, STOCK, MANUAL
)

/**
 * Request para validar una identificación
 */
data class ValidateIdentificationRequestDTO(
    val imageHash: String,
    val suggestedProductId: Long?,
    val actualProductId: Long?,
    val confidenceScore: BigDecimal,
    val matchType: String,
    val wasCorrect: Boolean,
    val userId: Long,
    val notes: String? = null,
    val source: String = "MANUAL",
    val relatedSaleId: Long? = null,
    val relatedStockId: Long? = null
)

// ============================================================================
// Response DTOs
// ============================================================================

/**
 * DTO para resultado de identificación de producto
 */
data class ProductIdentificationResultDTO(
    val status: String,  // IDENTIFIED, PARTIAL_MATCH, NEW_PRODUCT_CREATED, MULTIPLE_MATCHES, ERROR
    val product: ProductSummaryDTO,
    val isExisting: Boolean,
    val confidence: BigDecimal,
    val matchType: String?,  // EXACT_BARCODE, EXACT_HASH, BRAND_MODEL, etc.
    val similarity: BigDecimal?,
    val requiresValidation: Boolean,
    val details: String,
    val alternativeMatches: List<IdentificationMatchDTO>,
    val processingTimeMs: Long,
    val metadata: Map<String, Any>
)

/**
 * DTO para un match de identificación individual
 */
data class IdentificationMatchDTO(
    val product: ProductSummaryDTO,
    val confidence: BigDecimal,
    val matchType: String,
    val details: String,
    val similarity: BigDecimal?,
    val metadata: Map<String, Any>
)

/**
 * DTO resumido de producto (para evitar circular references y reducir payload)
 */
data class ProductSummaryDTO(
    val id: Long,
    val name: String,
    val description: String?,
    val imageUrl: String?,
    val categoryId: Long,
    val stockQuantity: Int?,
    val barcodeData: String?,
    val brandName: String?,
    val modelNumber: String?,
    val inferredCategory: String?,
    val recognitionAccuracy: BigDecimal?
)

/**
 * DTO para validación de identificación
 */
data class ProductIdentificationValidationDTO(
    val validationId: Long?,
    val imageHash: String,
    val imageUrl: String?,
    val suggestedProductId: Long?,
    val actualProductId: Long?,
    val confidenceScore: BigDecimal,
    val matchType: String,
    val similarityScore: BigDecimal?,
    val wasCorrect: Boolean,
    val correctionType: String,
    val validatedBy: Long,
    val validatedAt: LocalDateTime,
    val feedbackNotes: String?,
    val validationSource: String,
    val relatedSaleId: Long?,
    val relatedStockId: Long?
)

/**
 * DTO para configuración de umbrales
 */
data class IdentificationThresholdConfigDTO(
    val configId: Long?,
    val barcodeMinConfidence: BigDecimal,
    val hashMinConfidence: BigDecimal,
    val brandModelMinConfidence: BigDecimal,
    val vectorSimilarityMinConfidence: BigDecimal,
    val tagCategoryMinConfidence: BigDecimal,
    val autoApproveThreshold: BigDecimal,
    val manualValidationThreshold: BigDecimal,
    val totalIdentifications: Int,
    val correctIdentifications: Int,
    val falsePositives: Int,
    val falseNegatives: Int,
    val accuracy: BigDecimal?,
    val lastTrainingAt: LocalDateTime?,
    val modelVersion: String,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

/**
 * DTO para métricas de precisión
 */
data class AccuracyMetricsDTO(
    val totalValidations: Int,
    val correctValidations: Int,
    val falsePositives: Int,
    val falseNegatives: Int,
    val accuracy: BigDecimal,
    val accuracyPercentage: String
)

/**
 * DTO para respuesta genérica de success/error
 */
data class ApiResponseDTO<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: String? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
)

// ============================================================================
// Extension Functions - Domain to DTO
// ============================================================================

fun ProductIdentificationResult.toDTO(): ProductIdentificationResultDTO {
    return ProductIdentificationResultDTO(
        status = this.status.name,
        product = this.product.toSummaryDTO(),
        isExisting = this.isExisting,
        confidence = this.confidence,
        matchType = this.matchType?.name,
        similarity = this.similarity,
        requiresValidation = this.requiresValidation,
        details = this.details,
        alternativeMatches = this.alternativeMatches.map { it.toDTO() },
        processingTimeMs = this.processingTimeMs,
        metadata = this.metadata
    )
}

fun IdentificationMatch.toDTO(): IdentificationMatchDTO {
    return IdentificationMatchDTO(
        product = this.product.toSummaryDTO(),
        confidence = this.confidence,
        matchType = this.matchType.name,
        details = this.details,
        similarity = this.similarity,
        metadata = this.metadata
    )
}

fun Product.toSummaryDTO(): ProductSummaryDTO {
    return ProductSummaryDTO(
        id = this.id,
        name = this.name,
        description = this.description,
        imageUrl = this.imageUrl,
        categoryId = this.categoryId,
        stockQuantity = this.stockQuantity,
        barcodeData = this.barcodeData,
        brandName = this.brandName,
        modelNumber = this.modelNumber,
        inferredCategory = this.inferredCategory,
        recognitionAccuracy = this.recognitionAccuracy
    )
}

fun ProductIdentificationValidation.toDTO(): ProductIdentificationValidationDTO {
    return ProductIdentificationValidationDTO(
        validationId = this.validationId,
        imageHash = this.imageHash,
        imageUrl = this.imageUrl,
        suggestedProductId = this.suggestedProductId,
        actualProductId = this.actualProductId,
        confidenceScore = this.confidenceScore,
        matchType = this.matchType,
        similarityScore = this.similarityScore,
        wasCorrect = this.wasCorrect,
        correctionType = this.correctionType.name,
        validatedBy = this.validatedBy,
        validatedAt = this.validatedAt,
        feedbackNotes = this.feedbackNotes,
        validationSource = this.validationSource.name,
        relatedSaleId = this.relatedSaleId,
        relatedStockId = this.relatedStockId
    )
}

fun IdentificationThresholdConfig.toDTO(): IdentificationThresholdConfigDTO {
    return IdentificationThresholdConfigDTO(
        configId = this.configId,
        barcodeMinConfidence = this.barcodeMinConfidence,
        hashMinConfidence = this.hashMinConfidence,
        brandModelMinConfidence = this.brandModelMinConfidence,
        vectorSimilarityMinConfidence = this.vectorSimilarityMinConfidence,
        tagCategoryMinConfidence = this.tagCategoryMinConfidence,
        autoApproveThreshold = this.autoApproveThreshold,
        manualValidationThreshold = this.manualValidationThreshold,
        totalIdentifications = this.totalIdentifications,
        correctIdentifications = this.correctIdentifications,
        falsePositives = this.falsePositives,
        falseNegatives = this.falseNegatives,
        accuracy = this.accuracy,
        lastTrainingAt = this.lastTrainingAt,
        modelVersion = this.modelVersion,
        isActive = this.isActive,
        createdAt = this.createdAt,
        updatedAt = this.updatedAt
    )
}

// ============================================================================
// Extension Functions - DTO to Domain
// ============================================================================

fun IdentifyOrCreateProductRequestDTO.toDomain(imageBytes: ByteArray): IdentifyOrCreateProductRequest {
    return IdentifyOrCreateProductRequest(
        imageBytes = imageBytes,
        imageFormat = this.imageFormat,
        name = this.name,
        description = this.description,
        categoryId = this.categoryId,
        stockQuantity = this.stockQuantity,
        expirationDate = this.expirationDate,
        source = ValidationSource.valueOf(this.source)
    )
}

fun ValidateIdentificationRequestDTO.toDomain(): ValidateIdentificationRequest {
    return ValidateIdentificationRequest(
        imageHash = this.imageHash,
        suggestedProductId = this.suggestedProductId,
        actualProductId = this.actualProductId,
        confidenceScore = this.confidenceScore,
        matchType = this.matchType,
        wasCorrect = this.wasCorrect,
        userId = this.userId,
        notes = this.notes,
        source = ValidationSource.valueOf(this.source),
        relatedSaleId = this.relatedSaleId,
        relatedStockId = this.relatedStockId
    )
}
