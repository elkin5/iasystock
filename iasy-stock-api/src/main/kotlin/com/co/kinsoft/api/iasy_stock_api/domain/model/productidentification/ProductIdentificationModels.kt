package com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import java.math.BigDecimal
import java.time.LocalDateTime

/**
 * Resultado de identificación de producto
 */
data class IdentificationMatch(
    val product: Product,
    val confidence: BigDecimal,
    val matchType: MatchType,
    val details: String,
    val similarity: BigDecimal? = null,
    val metadata: Map<String, Any> = emptyMap()
)

/**
 * Tipos de match de identificación
 */
enum class MatchType {
    EXACT_BARCODE,      // 100% confianza - Match exacto por código de barras
    EXACT_HASH,         // 100% confianza - Match exacto por hash de imagen
    BRAND_MODEL,        // 90% confianza - Match por marca y modelo
    VISION_MATCH,       // 60-100% - Match por campos Vision (brand + model + category + logos/objects)
    VECTOR_SIMILARITY,  // Variable - Match por similitud con embeddings OpenAI
    TAG_CATEGORY,       // 60% confianza - Match por tags y categoría
    MULTI_FACTOR        // Variable - Combinación de múltiples factores
}

/**
 * Resultado completo de identificación o creación de producto
 */
data class ProductIdentificationResult(
    val status: IdentificationStatus,
    val product: Product,
    val isExisting: Boolean,
    val confidence: BigDecimal,
    val matchType: MatchType? = null,
    val similarity: BigDecimal? = null,
    val requiresValidation: Boolean,
    val details: String,
    val alternativeMatches: List<IdentificationMatch> = emptyList(),
    val processingTimeMs: Long,
    val metadata: Map<String, Any> = emptyMap()
)

/**
 * Estados de identificación
 */
enum class IdentificationStatus {
    IDENTIFIED,          // Producto identificado con alta confianza
    PARTIAL_MATCH,       // Match parcial que requiere validación
    NEW_PRODUCT_CREATED, // Nuevo producto creado
    MULTIPLE_MATCHES,    // Múltiples coincidencias encontradas
    ERROR                // Error en el proceso
}

/**
 * Configuración de umbrales para identificación
 */
data class IdentificationThresholdConfig(
    val configId: Long? = null,
    val barcodeMinConfidence: BigDecimal = BigDecimal("0.95"),
    val hashMinConfidence: BigDecimal = BigDecimal("1.0"),
    val brandModelMinConfidence: BigDecimal = BigDecimal("0.85"),
    val vectorSimilarityMinConfidence: BigDecimal = BigDecimal("0.75"),
    val tagCategoryMinConfidence: BigDecimal = BigDecimal("0.60"),
    val autoApproveThreshold: BigDecimal = BigDecimal("0.95"),
    val manualValidationThreshold: BigDecimal = BigDecimal("0.75"),
    val totalIdentifications: Int = 0,
    val correctIdentifications: Int = 0,
    val falsePositives: Int = 0,
    val falseNegatives: Int = 0,
    val accuracy: BigDecimal? = null,
    val lastTrainingAt: LocalDateTime? = null,
    val trainingSamplesCount: Int = 0,
    val modelVersion: String = "1.0",
    val isActive: Boolean = true,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

/**
 * Validación de identificación por humano
 */
data class ProductIdentificationValidation(
    val validationId: Long? = null,
    val imageHash: String,
    val imageUrl: String? = null,
    val imageEmbedding: String? = null,
    val suggestedProductId: Long? = null,
    val actualProductId: Long? = null,
    val confidenceScore: BigDecimal,
    val matchType: String,
    val similarityScore: BigDecimal? = null,
    val wasCorrect: Boolean,
    val correctionType: CorrectionType,
    val validatedBy: Long,
    val validatedAt: LocalDateTime = LocalDateTime.now(),
    val feedbackNotes: String? = null,
    val validationSource: ValidationSource,
    val relatedSaleId: Long? = null,
    val relatedStockId: Long? = null,
    val metadata: String? = null,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

/**
 * Tipos de corrección en validación
 */
enum class CorrectionType {
    CORRECT,         // La identificación fue correcta
    FALSE_POSITIVE,  // Se identificó como existente pero era nuevo
    FALSE_NEGATIVE,  // No se identificó pero existía
    IMPROVED         // Se mejoró la identificación
}

/**
 * Fuente de validación
 */
enum class ValidationSource {
    SALE,    // Validación desde flujo de venta
    STOCK,   // Validación desde flujo de stock
    MANUAL   // Validación manual explícita
}

/**
 * Request para identificar o crear producto
 */
data class IdentifyOrCreateProductRequest(
    val imageBytes: ByteArray,
    val imageFormat: String = "jpeg",
    val name: String? = null,
    val description: String? = null,
    val categoryId: Long? = null,
    val stockQuantity: Int? = null,
    val expirationDate: String? = null,
    val source: ValidationSource = ValidationSource.MANUAL
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as IdentifyOrCreateProductRequest

        if (!imageBytes.contentEquals(other.imageBytes)) return false
        if (imageFormat != other.imageFormat) return false
        if (name != other.name) return false
        if (description != other.description) return false
        if (categoryId != other.categoryId) return false
        if (stockQuantity != other.stockQuantity) return false
        if (expirationDate != other.expirationDate) return false

        return true
    }

    override fun hashCode(): Int {
        var result = imageBytes.contentHashCode()
        result = 31 * result + imageFormat.hashCode()
        result = 31 * result + (name?.hashCode() ?: 0)
        result = 31 * result + (description?.hashCode() ?: 0)
        result = 31 * result + (categoryId?.hashCode() ?: 0)
        result = 31 * result + (stockQuantity ?: 0)
        result = 31 * result + (expirationDate?.hashCode() ?: 0)
        return result
    }
}

/**
 * Request para validar una identificación
 */
data class ValidateIdentificationRequest(
    val imageHash: String,
    val suggestedProductId: Long?,
    val actualProductId: Long?,
    val confidenceScore: BigDecimal,
    val matchType: String,
    val wasCorrect: Boolean,
    val userId: Long,
    val notes: String? = null,
    val source: ValidationSource = ValidationSource.MANUAL,
    val relatedSaleId: Long? = null,
    val relatedStockId: Long? = null
)
