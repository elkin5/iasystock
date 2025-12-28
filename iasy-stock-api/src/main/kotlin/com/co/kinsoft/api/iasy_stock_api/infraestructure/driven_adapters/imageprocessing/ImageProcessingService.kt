package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.imageprocessing

import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.*
import com.google.zxing.*
import com.google.zxing.client.j2se.BufferedImageLuminanceSource
import com.google.zxing.common.HybridBinarizer
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.awt.Color
import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.math.BigDecimal
import java.security.MessageDigest
import javax.imageio.ImageIO
import kotlin.math.sqrt

@Service
class ImageProcessingService {
    
    private val logger: Logger = LoggerFactory.getLogger(ImageProcessingService::class.java)
    
    /**
     * Calcula la puntuación de calidad de una imagen
     */
    fun calculateImageQuality(imageBytes: ByteArray): Mono<BigDecimal> {
        return Mono.fromCallable {
            try {
                val image = ImageIO.read(ByteArrayInputStream(imageBytes))
                if (image == null) {
                    BigDecimal.ZERO
                } else {
                    val quality = calculateQualityScore(image)
                    logger.info("Calidad de imagen calculada: $quality")
                    quality
                }
            } catch (e: Exception) {
                logger.error("Error calculando calidad de imagen: ${e.message}", e)
                BigDecimal.ZERO
            }
        }
    }
    
    /**
     * Analiza colores dominantes en una imagen
     */
    fun analyzeDominantColors(imageBytes: ByteArray): Mono<ColorAnalysisResult> {
        return Mono.fromCallable {
            try {
                val image = ImageIO.read(ByteArrayInputStream(imageBytes))
                if (image == null) {
                    ColorAnalysisResult(emptyList(), "[]")
                } else {
                    val colors = extractDominantColors(image)
                    val colorPalette = colors.joinToString(",") { "\"${it.color}\"" }
                    ColorAnalysisResult(colors, "[$colorPalette]")
                }
            } catch (e: Exception) {
                logger.error("Error analizando colores: ${e.message}", e)
                ColorAnalysisResult(emptyList(), "[]")
            }
        }
    }
    
    /**
     * Detecta códigos de barras en una imagen
     */
    fun detectBarcodes(imageBytes: ByteArray): Mono<BarcodeDetectionResult> {
        return Mono.fromCallable {
            try {
                // Implementación básica - en producción usar librería como ZXing
                val barcodes = detectBarcodesBasic(imageBytes)
                BarcodeDetectionResult(barcodes, BigDecimal("0.8"))
            } catch (e: Exception) {
                logger.error("Error detectando códigos de barras: ${e.message}", e)
                BarcodeDetectionResult(emptyList(), BigDecimal.ZERO)
            }
        }
    }
    
    /**
     * Genera hash único de imagen
     */
    fun generateImageHash(imageBytes: ByteArray): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hashBytes = digest.digest(imageBytes)
            hashBytes.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            logger.error("Error generando hash de imagen: ${e.message}", e)
            "hash_error_${System.currentTimeMillis()}"
        }
    }
    
    /**
     * Determina el formato de imagen
     */
    fun detectImageFormat(imageBytes: ByteArray): String {
        return try {
            val inputStream = ByteArrayInputStream(imageBytes)
            val readers = ImageIO.getImageReaders(inputStream)
            if (readers.hasNext()) {
                readers.next().formatName.lowercase()
            } else {
                "unknown"
            }
        } catch (e: Exception) {
            logger.error("Error detectando formato de imagen: ${e.message}", e)
            "unknown"
        }
    }
    
    private fun calculateQualityScore(image: BufferedImage): BigDecimal {
        val width = image.width
        val height = image.height
        
        // Factores de calidad
        val resolutionScore = calculateResolutionScore(width, height)
        val brightnessScore = calculateBrightnessScore(image)
        val contrastScore = calculateContrastScore(image)
        val sharpnessScore = calculateSharpnessScore(image)
        
        // Peso de cada factor
        val weightedScore = (resolutionScore * BigDecimal("0.3") +
                brightnessScore * BigDecimal("0.25") +
                contrastScore * BigDecimal("0.25") +
                sharpnessScore * BigDecimal("0.2"))
        
        return weightedScore.coerceAtMost(BigDecimal.ONE)
    }
    
    private fun calculateResolutionScore(width: Int, height: Int): BigDecimal {
        val totalPixels = width * height
        return when {
            totalPixels >= 2000000 -> BigDecimal("1.0") // 2MP+
            totalPixels >= 1000000 -> BigDecimal("0.8") // 1MP
            totalPixels >= 500000 -> BigDecimal("0.6")  // 0.5MP
            totalPixels >= 100000 -> BigDecimal("0.4")  // 0.1MP
            else -> BigDecimal("0.2")
        }
    }
    
    private fun calculateBrightnessScore(image: BufferedImage): BigDecimal {
        var totalBrightness = 0.0
        val sampleSize = 100
        val stepX = image.width / sampleSize
        val stepY = image.height / sampleSize
        
        for (x in 0 until sampleSize) {
            for (y in 0 until sampleSize) {
                val pixelX = x * stepX
                val pixelY = y * stepY
                if (pixelX < image.width && pixelY < image.height) {
                    val rgb = image.getRGB(pixelX, pixelY)
                    val color = Color(rgb)
                    val brightness = (color.red + color.green + color.blue) / 3.0 / 255.0
                    totalBrightness += brightness
                }
            }
        }
        
        val avgBrightness = totalBrightness / (sampleSize * sampleSize)
        return when {
            avgBrightness in 0.3..0.7 -> BigDecimal("1.0") // Rango óptimo
            avgBrightness in 0.2..0.8 -> BigDecimal("0.8") // Rango aceptable
            avgBrightness in 0.1..0.9 -> BigDecimal("0.6") // Rango tolerable
            else -> BigDecimal("0.3") // Muy oscuro o muy claro
        }
    }
    
    private fun calculateContrastScore(image: BufferedImage): BigDecimal {
        val sampleSize = 50
        val stepX = image.width / sampleSize
        val stepY = image.height / sampleSize
        
        val brightnessValues = mutableListOf<Double>()
        
        for (x in 0 until sampleSize) {
            for (y in 0 until sampleSize) {
                val pixelX = x * stepX
                val pixelY = y * stepY
                if (pixelX < image.width && pixelY < image.height) {
                    val rgb = image.getRGB(pixelX, pixelY)
                    val color = Color(rgb)
                    val brightness = (color.red + color.green + color.blue) / 3.0 / 255.0
                    brightnessValues.add(brightness)
                }
            }
        }
        
        if (brightnessValues.isEmpty()) return BigDecimal.ZERO
        
        val mean = brightnessValues.average()
        val variance = brightnessValues.map { (it - mean) * (it - mean) }.average()
        val stdDev = sqrt(variance)
        
        return when {
            stdDev > 0.3 -> BigDecimal("1.0") // Alto contraste
            stdDev > 0.2 -> BigDecimal("0.8") // Buen contraste
            stdDev > 0.1 -> BigDecimal("0.6") // Contraste moderado
            else -> BigDecimal("0.3") // Bajo contraste
        }
    }
    
    private fun calculateSharpnessScore(image: BufferedImage): BigDecimal {
        // Implementación simplificada de detección de nitidez
        // En producción usar algoritmos más sofisticados como Laplacian
        return BigDecimal("0.8") // Valor por defecto
    }
    
    private fun extractDominantColors(image: BufferedImage): List<ColorInfo> {
        val colorMap = mutableMapOf<String, Int>()
        val sampleSize = 50
        val stepX = image.width / sampleSize
        val stepY = image.height / sampleSize
        
        for (x in 0 until sampleSize) {
            for (y in 0 until sampleSize) {
                val pixelX = x * stepX
                val pixelY = y * stepY
                if (pixelX < image.width && pixelY < image.height) {
                    val rgb = image.getRGB(pixelX, pixelY)
                    val color = Color(rgb)
                    val colorKey = "${color.red},${color.green},${color.blue}"
                    colorMap[colorKey] = colorMap.getOrDefault(colorKey, 0) + 1
                }
            }
        }
        
        val totalPixels = sampleSize * sampleSize
        return colorMap.entries
            .sortedByDescending { it.value }
            .take(5)
            .map { entry ->
                val rgb = entry.key.split(",")
                val percentage = BigDecimal(entry.value) / BigDecimal(totalPixels) * BigDecimal("100")
                ColorInfo(
                    color = entry.key,
                    percentage = percentage,
                    rgb = "rgb(${rgb[0]},${rgb[1]},${rgb[2]})"
                )
            }
    }
    
    private fun detectBarcodesBasic(imageBytes: ByteArray): List<DetectedBarcode> {
        return try {
            val image = ImageIO.read(ByteArrayInputStream(imageBytes))
            if (image == null) {
                logger.warn("No se pudo leer la imagen para detección de códigos de barras")
                return emptyList()
            }

            val barcodes = mutableListOf<DetectedBarcode>()

            // Detectar múltiples formatos de códigos de barras
            val formats = listOf(
                BarcodeFormat.QR_CODE,
                BarcodeFormat.EAN_13,
                BarcodeFormat.EAN_8,
                BarcodeFormat.UPC_A,
                BarcodeFormat.UPC_E,
                BarcodeFormat.CODE_128,
                BarcodeFormat.CODE_39,
                BarcodeFormat.CODE_93,
                BarcodeFormat.CODABAR,
                BarcodeFormat.ITF,
                BarcodeFormat.DATA_MATRIX,
                BarcodeFormat.PDF_417
            )

            // Intentar con MultiFormatReader primero (más rápido)
            try {
                val source = BufferedImageLuminanceSource(image)
                val bitmap = BinaryBitmap(HybridBinarizer(source))
                val reader = MultiFormatReader()

                // Configurar hints para mejor detección
                val hints = mapOf(
                    DecodeHintType.TRY_HARDER to true,
                    DecodeHintType.POSSIBLE_FORMATS to formats,
                    DecodeHintType.PURE_BARCODE to false
                )

                val result = reader.decode(bitmap, hints)

                barcodes.add(
                    DetectedBarcode(
                        data = result.text,
                        format = result.barcodeFormat.name,
                        confidence = BigDecimal("0.95"), // Alta confianza para detección directa
                        rawBytes = result.rawBytes?.joinToString("") { "%02x".format(it) }
                    )
                )

                logger.info("Código de barras detectado: ${result.text} (${result.barcodeFormat})")
            } catch (e: NotFoundException) {
                logger.debug("No se detectó código de barras con MultiFormatReader, intentando con búsqueda exhaustiva")

                // Si no se detecta con MultiFormatReader, intentar con cada formato individualmente
                for (format in formats) {
                    try {
                        val source = BufferedImageLuminanceSource(image)
                        val bitmap = BinaryBitmap(HybridBinarizer(source))
                        val reader = MultiFormatReader()

                        val hints = mapOf(
                            DecodeHintType.TRY_HARDER to true,
                            DecodeHintType.POSSIBLE_FORMATS to listOf(format)
                        )

                        val result = reader.decode(bitmap, hints)

                        barcodes.add(
                            DetectedBarcode(
                                data = result.text,
                                format = result.barcodeFormat.name,
                                confidence = BigDecimal("0.90"), // Confianza ligeramente menor
                                rawBytes = result.rawBytes?.joinToString("") { "%02x".format(it) }
                            )
                        )

                        logger.info("Código de barras detectado (búsqueda exhaustiva): ${result.text} (${result.barcodeFormat})")
                        break // Salir después de la primera detección exitosa
                    } catch (e: NotFoundException) {
                        // Continuar con el siguiente formato
                    }
                }
            }

            if (barcodes.isEmpty()) {
                logger.debug("No se detectaron códigos de barras en la imagen")
            }

            barcodes
        } catch (e: Exception) {
            logger.error("Error detectando códigos de barras con ZXing: ${e.message}", e)
            emptyList()
        }
    }
} 