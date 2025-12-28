package com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import java.math.BigDecimal

/**
 * Request para detectar múltiples productos en una sola imagen
 */
data class MultipleProductDetectionRequest(
    val imageBase64: String,
    val imageFormat: String = "jpeg",
    val source: String,
    val userId: Long? = null,
    val groupByProduct: Boolean = true,
    val minConfidence: BigDecimal? = null
)

/**
 * Objeto detectado por GPT-4 Vision con su ubicación en la imagen
 */
data class DetectedObject(
    val objectClass: String,
    val confidence: BigDecimal,
    val boundingBox: BoundingBox,
    val objectIndex: Int,
    val croppedImageBase64: String? = null  // Imagen recortada del objeto en base64
)

/**
 * Bounding box normalizado (coordenadas 0-1)
 */
data class BoundingBox(
    val x: Double,      // Centro X normalizado (0-1)
    val y: Double,      // Centro Y normalizado (0-1)
    val width: Double,  // Ancho normalizado (0-1)
    val height: Double  // Alto normalizado (0-1)
)

/**
 * Producto detectado e identificado con su ubicación y confianzas
 */
data class DetectedProductMatch(
    val product: Product,
    val boundingBox: BoundingBox,
    val detectionConfidence: BigDecimal,      // Confianza de detección (GPT-4 Vision)
    val identificationConfidence: BigDecimal,  // Confianza de identificación
    val combinedConfidence: BigDecimal,        // Confianza combinada (detection × identification)
    val matchType: String,
    val similarity: BigDecimal?,
    val alternativeMatches: List<IdentificationMatch>,
    val objectIndex: Int
)

/**
 * Grupo de productos del mismo tipo detectados en la imagen
 */
data class DetectedProductGroup(
    val product: Product,
    val quantity: Int,
    val averageConfidence: BigDecimal,
    val detections: List<DetectedProductMatch>,
    val isConfirmed: Boolean = true
)

/**
 * Resultado de la detección múltiple
 */
data class MultipleProductDetectionResult(
    val status: IdentificationStatus,
    val productGroups: List<DetectedProductGroup>,
    val totalDetections: Int,
    val uniqueProducts: Int,
    val requiresValidation: Boolean,
    val processingTimeMs: Long,
    val metadata: Map<String, Any>
)
