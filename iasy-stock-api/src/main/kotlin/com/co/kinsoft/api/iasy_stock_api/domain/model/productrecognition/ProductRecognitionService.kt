package com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition

import reactor.core.publisher.Mono
import java.math.BigDecimal

interface ProductRecognitionService {

    /**
     * Procesa una imagen de producto y extrae toda la información automáticamente
     */
    fun processProductImage(imageBytes: ByteArray, imageFormat: String): Mono<ProductRecognitionResult>
}

data class ProductRecognitionResult(
    val imageEmbedding: String,
    val embeddingModel: String,
    val embeddingConfidence: BigDecimal,
    val imageHash: String,
    val imageQualityScore: BigDecimal,
    val imageFormat: String,
    val imageSizeBytes: Int,
    val barcodeData: String?,
    val brandName: String?,
    val modelNumber: String?,
    val dominantColors: String,
    val textOcr: String,
    val logoDetection: String,
    val objectDetection: String,
    val recognitionAccuracy: BigDecimal,
    val inferredCategory: String,
    val inferredPriceRange: String,
    val inferredUsageTags: List<String>,
    val confidenceScores: String
)

data class ImageEmbeddingResult(
    val embedding: String, // Base64 encoded vector
    val model: String,
    val confidence: BigDecimal,
    val dimensions: Int
)


data class ColorAnalysisResult(
    val dominantColors: List<ColorInfo>,
    val colorPalette: String
)

data class ColorInfo(
    val color: String,
    val percentage: BigDecimal,
    val rgb: String
)

data class BarcodeDetectionResult(
    val barcodes: List<DetectedBarcode>,
    val confidence: BigDecimal
)

data class DetectedBarcode(
    val data: String,
    val format: String,
    val confidence: BigDecimal,
    val rawBytes: String? = null
) 