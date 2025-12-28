package com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification

import java.math.BigDecimal

/**
 * DTOs para comunicación con el frontend
 */

data class MultipleProductDetectionRequestDTO(
    val imageBase64: String,
    val imageFormat: String = "jpeg",
    val source: String,
    val userId: Long? = null,
    val groupByProduct: Boolean = true,
    val minConfidence: BigDecimal? = null
)

data class BoundingBoxDTO(
    val x: Double,
    val y: Double,
    val width: Double,
    val height: Double
)

data class DetectedProductMatchDTO(
    val product: ProductSummaryDTO,
    val boundingBox: BoundingBoxDTO,
    val detectionConfidence: BigDecimal,
    val identificationConfidence: BigDecimal,
    val combinedConfidence: BigDecimal,
    val matchType: String,
    val similarity: BigDecimal?,
    val alternativeMatches: List<IdentificationMatchDTO>,
    val objectIndex: Int
)

data class DetectedProductGroupDTO(
    val product: ProductSummaryDTO,
    val quantity: Int,
    val averageConfidence: BigDecimal,
    val detections: List<DetectedProductMatchDTO>,
    val isConfirmed: Boolean = true
)

data class MultipleProductDetectionResponseDTO(
    val status: String,
    val productGroups: List<DetectedProductGroupDTO>,
    val totalDetections: Int,
    val uniqueProducts: Int,
    val requiresValidation: Boolean,
    val processingTimeMs: Long,
    val metadata: Map<String, Any>
)

// Extension functions para conversión
fun MultipleProductDetectionRequestDTO.toDomain(): MultipleProductDetectionRequest {
    return MultipleProductDetectionRequest(
        imageBase64 = this.imageBase64,
        imageFormat = this.imageFormat,
        source = this.source,
        userId = this.userId,
        groupByProduct = this.groupByProduct,
        minConfidence = this.minConfidence
    )
}

fun BoundingBox.toDTO(): BoundingBoxDTO {
    return BoundingBoxDTO(
        x = this.x,
        y = this.y,
        width = this.width,
        height = this.height
    )
}

fun DetectedProductMatch.toDTO(): DetectedProductMatchDTO {
    return DetectedProductMatchDTO(
        product = this.product.toSummaryDTO(),
        boundingBox = this.boundingBox.toDTO(),
        detectionConfidence = this.detectionConfidence,
        identificationConfidence = this.identificationConfidence,
        combinedConfidence = this.combinedConfidence,
        matchType = this.matchType,
        similarity = this.similarity,
        alternativeMatches = this.alternativeMatches.map { it.toDTO() },
        objectIndex = this.objectIndex
    )
}

fun DetectedProductGroup.toDTO(): DetectedProductGroupDTO {
    return DetectedProductGroupDTO(
        product = this.product.toSummaryDTO(),
        quantity = this.quantity,
        averageConfidence = this.averageConfidence,
        detections = this.detections.map { it.toDTO() },
        isConfirmed = this.isConfirmed
    )
}

fun MultipleProductDetectionResult.toDTO(): MultipleProductDetectionResponseDTO {
    return MultipleProductDetectionResponseDTO(
        status = this.status.name,
        productGroups = this.productGroups.map { it.toDTO() },
        totalDetections = this.totalDetections,
        uniqueProducts = this.uniqueProducts,
        requiresValidation = this.requiresValidation,
        processingTimeMs = this.processingTimeMs,
        metadata = this.metadata
    )
}
