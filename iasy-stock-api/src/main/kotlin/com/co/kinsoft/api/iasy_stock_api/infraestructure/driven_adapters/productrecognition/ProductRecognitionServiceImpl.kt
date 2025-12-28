package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.productrecognition

import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.BarcodeDetectionResult
import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ColorAnalysisResult
import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ImageEmbeddingResult
import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ProductRecognitionResult
import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ProductRecognitionService
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.imageprocessing.ImageProcessingService
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.OpenAIService
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDateTime

@Service
class ProductRecognitionServiceImpl(
    private val openAIService: OpenAIService,
    private val imageProcessingService: ImageProcessingService,
    private val objectMapper: ObjectMapper
) : ProductRecognitionService {

    private val logger: Logger = LoggerFactory.getLogger(ProductRecognitionServiceImpl::class.java)

    override fun processProductImage(imageBytes: ByteArray, imageFormat: String): Mono<ProductRecognitionResult> {
        logger.info("Iniciando procesamiento de imagen de producto")

        return Mono.zip(
            openAIService.generateImageEmbedding(imageBytes),
            openAIService.analyzeImage(imageBytes),
            imageProcessingService.calculateImageQuality(imageBytes),
            imageProcessingService.analyzeDominantColors(imageBytes),
            imageProcessingService.detectBarcodes(imageBytes)
        ).flatMap { tuple ->
            val embedding = tuple.t1
            val analysis = tuple.t2
            val quality = tuple.t3
            val colors = tuple.t4
            val barcodes = tuple.t5
            // Procesar información extraída
            val imageHash = imageProcessingService.generateImageHash(imageBytes)
//            val detectedFormat = imageProcessingService.detectImageFormat(imageBytes)

            // Infereir información adicional EN PARALELO para optimizar tiempo
            Mono.zip(
                openAIService.inferProductCategory(analysis.objects, analysis.text, analysis.logos),
                openAIService.inferPriceRange(analysis.brand, analysis.category, analysis.objects),
                openAIService.inferUsageTags(analysis.category, analysis.objects, analysis.text)
            ).map { inferenceTuple ->
                    val inferredCategory = inferenceTuple.t1
                    val inferredPriceRange = inferenceTuple.t2
                    val inferredUsageTags = inferenceTuple.t3
                    // Calcular precisión general
                    val recognitionAccuracy = calculateOverallAccuracy(
                        embedding.confidence,
                        quality,
                        analysis.objects.isNotEmpty(),
                        analysis.text.isNotBlank(),
                        analysis.logos.isNotEmpty()
                    )

                    // Crear metadatos JSON
                    val metadata = createMetadata(analysis, colors, barcodes)
                    val confidenceScores = createConfidenceScores(embedding, quality, analysis)

                    ProductRecognitionResult(
                        imageEmbedding = embedding.embedding,
                        embeddingModel = embedding.model,
                        embeddingConfidence = embedding.confidence,
                        imageHash = imageHash,
                        imageQualityScore = quality,
                        imageFormat = imageFormat,
                        imageSizeBytes = imageBytes.size,
                        barcodeData = when (analysis.barcodes) {
                            is List<*> -> (analysis.barcodes as List<String>).firstOrNull()
                            else -> null
                        },
                        brandName = analysis.brand?.ifBlank { null },
                        modelNumber = analysis.model?.ifBlank { null },
                        dominantColors = colors.colorPalette,
                        textOcr = createOcrJson(analysis.text),
                        logoDetection = createLogoJson(analysis.logos),
                        objectDetection = createObjectJson(analysis.objects),
                        recognitionAccuracy = recognitionAccuracy,
                        inferredCategory = inferredCategory.ifBlank { analysis.category.ifBlank { "Otros" } },
                        inferredPriceRange = inferredPriceRange.ifBlank { analysis.priceRange.ifBlank { "medio" } },
                        inferredUsageTags = inferredUsageTags.ifEmpty { analysis.usageTags },
                        confidenceScores = confidenceScores
                    )
                }
        }.doOnSuccess { result ->
            logger.info("Procesamiento completado - Precisión: ${result.recognitionAccuracy}")
        }.doOnError { error ->
            logger.error("Error en procesamiento de imagen: ${error.message}", error)
        }
    }

    private fun calculateOverallAccuracy(
        embeddingConfidence: BigDecimal,
        imageQuality: BigDecimal,
        hasObjects: Boolean,
        hasText: Boolean,
        hasLogos: Boolean
    ): BigDecimal {
        var totalScore = BigDecimal.ZERO
        var weightSum = BigDecimal.ZERO

        // Peso del embedding
        totalScore += embeddingConfidence * BigDecimal("0.4")
        weightSum += BigDecimal("0.4")

        // Peso de la calidad de imagen
        totalScore += imageQuality * BigDecimal("0.2")
        weightSum += BigDecimal("0.2")

        // Peso de detecciones
        if (hasObjects) {
            totalScore += BigDecimal("0.15")
            weightSum += BigDecimal("0.15")
        }

        if (hasText) {
            totalScore += BigDecimal("0.15")
            weightSum += BigDecimal("0.15")
        }

        if (hasLogos) {
            totalScore += BigDecimal("0.1")
            weightSum += BigDecimal("0.1")
        }

        return if (weightSum > BigDecimal.ZERO) {
            totalScore / weightSum
        } else {
            BigDecimal.ZERO
        }
    }

    private fun createMetadata(
        analysis: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.ImageAnalysisResult,
        colors: ColorAnalysisResult,
        barcodes: BarcodeDetectionResult
    ): String {
        val metadata = mapOf(
            "processing_timestamp" to LocalDateTime.now().toString(),
            "objects_detected" to analysis.objects.size,
            "text_extracted" to analysis.text.isNotBlank(),
            "logos_detected" to analysis.logos.size,
            "barcodes_detected" to barcodes.barcodes.size,
            "colors_analyzed" to colors.dominantColors.size,
            "analysis_version" to "1.0"
        )

        return try {
            objectMapper.writeValueAsString(metadata)
        } catch (e: Exception) {
            logger.error("Error creando metadatos JSON: ${e.message}", e)
            "{}"
        }
    }

    private fun createConfidenceScores(
        embedding: ImageEmbeddingResult,
        quality: BigDecimal,
        analysis: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.ImageAnalysisResult
    ): String {
        val scores = mapOf(
            "embedding_confidence" to embedding.confidence,
            "image_quality" to quality,
            "object_detection" to if (analysis.objects.isNotEmpty()) BigDecimal("0.85") else BigDecimal.ZERO,
            "text_extraction" to if (analysis.text.isNotBlank()) BigDecimal("0.9") else BigDecimal.ZERO,
            "logo_detection" to if (analysis.logos.isNotEmpty()) BigDecimal("0.8") else BigDecimal.ZERO,
            "overall_confidence" to calculateOverallAccuracy(
                embedding.confidence,
                quality,
                analysis.objects.isNotEmpty(),
                analysis.text.isNotBlank(),
                analysis.logos.isNotEmpty()
            )
        )

        return try {
            objectMapper.writeValueAsString(scores)
        } catch (e: Exception) {
            logger.error("Error creando scores de confianza JSON: ${e.message}", e)
            "{}"
        }
    }

    private fun createOcrJson(text: String): String {
        val ocrData = mapOf(
            "extracted_text" to text,
            "confidence" to if (text.isNotBlank()) BigDecimal("0.9") else BigDecimal.ZERO,
            "timestamp" to LocalDateTime.now().toString()
        )

        return try {
            objectMapper.writeValueAsString(ocrData)
        } catch (e: Exception) {
            logger.error("Error creando OCR JSON: ${e.message}", e)
            "{}"
        }
    }

    private fun createLogoJson(logos: List<String>): String {
        val logoData = mapOf(
            "detected_logos" to logos,
            "confidence" to if (logos.isNotEmpty()) BigDecimal("0.8") else BigDecimal.ZERO,
            "timestamp" to LocalDateTime.now().toString()
        )

        return try {
            objectMapper.writeValueAsString(logoData)
        } catch (e: Exception) {
            logger.error("Error creando logo JSON: ${e.message}", e)
            "{}"
        }
    }

    private fun createObjectJson(objects: List<String>): String {
        val objectData = mapOf(
            "detected_objects" to objects,
            "confidence" to if (objects.isNotEmpty()) BigDecimal("0.85") else BigDecimal.ZERO,
            "timestamp" to LocalDateTime.now().toString()
        )

        return try {
            objectMapper.writeValueAsString(objectData)
        } catch (e: Exception) {
            logger.error("Error creando objeto JSON: ${e.message}", e)
            "{}"
        }
    }
} 