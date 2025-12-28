package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.product.utils

import com.fasterxml.jackson.databind.ObjectMapper
import org.springframework.http.codec.multipart.FilePart
import java.util.*

object ImageUtils {

    /**
     * Detecta el tipo MIME y extensión de una imagen basándose en los primeros bytes (magic numbers)
     */
    fun detectImageType(imageBytes: ByteArray): ImageTypeInfo {
        if (imageBytes.size < 4) {
            return ImageTypeInfo("unknown", "unknown", "application/octet-stream")
        }

        // Verificar magic numbers para diferentes formatos de imagen
        val firstBytes = imageBytes.take(4).toByteArray()

        return when {
            // JPEG
            firstBytes[0] == 0xFF.toByte() && firstBytes[1] == 0xD8.toByte() ->
                ImageTypeInfo("jpg", "jpeg", "image/jpeg")

            // PNG
            firstBytes[0] == 0x89.toByte() && firstBytes[1] == 0x50.toByte() &&
                    firstBytes[2] == 0x4E.toByte() && firstBytes[3] == 0x47.toByte() ->
                ImageTypeInfo("png", "png", "image/png")

            // GIF
            firstBytes[0] == 0x47.toByte() && firstBytes[1] == 0x49.toByte() &&
                    firstBytes[2] == 0x46.toByte() && firstBytes[3] == 0x38.toByte() ->
                ImageTypeInfo("gif", "gif", "image/gif")

            // WebP (verificar los primeros 12 bytes)
            imageBytes.size >= 12 &&
                    firstBytes[0] == 0x52.toByte() && firstBytes[1] == 0x49.toByte() &&
                    firstBytes[2] == 0x46.toByte() && firstBytes[3] == 0x46.toByte() &&
                    imageBytes[8] == 0x57.toByte() && imageBytes[9] == 0x45.toByte() &&
                    imageBytes[10] == 0x42.toByte() && imageBytes[11] == 0x50.toByte() ->
                ImageTypeInfo("webp", "webp", "image/webp")

            // BMP
            firstBytes[0] == 0x42.toByte() && firstBytes[1] == 0x4D.toByte() ->
                ImageTypeInfo("bmp", "bmp", "image/bmp")

            // TIFF
            (firstBytes[0] == 0x49.toByte() && firstBytes[1] == 0x49.toByte() &&
                    firstBytes[2] == 0x2A.toByte() && firstBytes[3] == 0x00.toByte()) ||
                    (firstBytes[0] == 0x4D.toByte() && firstBytes[1] == 0x4D.toByte() &&
                            firstBytes[2] == 0x00.toByte() && firstBytes[3] == 0x2A.toByte()) ->
                ImageTypeInfo("tiff", "tiff", "image/tiff")

            else -> {
                // Intentar detectar por el nombre del archivo si está disponible
                ImageTypeInfo("unknown", "unknown", "application/octet-stream")
            }
        }
    }

    /**
     * Detecta el tipo de imagen desde un FilePart
     */
    fun detectImageTypeFromFilePart(filePart: FilePart, imageBytes: ByteArray): ImageTypeInfo {
        // Primero intentar por magic numbers
        val detectedType = detectImageType(imageBytes)

        // Si se detectó correctamente, usar esa información
        if (detectedType.extension != "unknown") {
            return detectedType
        }

        // Si no se pudo detectar por magic numbers, intentar por el nombre del archivo
        val filename = filePart.filename() ?: ""
        val fileExtension = filename.substringAfterLast('.', "").lowercase()

        return when (fileExtension) {
            "jpg", "jpeg" -> ImageTypeInfo("jpg", "jpeg", "image/jpeg")
            "png" -> ImageTypeInfo("png", "png", "image/png")
            "gif" -> ImageTypeInfo("gif", "gif", "image/gif")
            "webp" -> ImageTypeInfo("webp", "webp", "image/webp")
            "bmp" -> ImageTypeInfo("bmp", "bmp", "image/bmp")
            "tiff", "tif" -> ImageTypeInfo("tiff", "tiff", "image/tiff")
            else -> ImageTypeInfo("unknown", fileExtension, "application/octet-stream")
        }
    }

    /**
     * Genera un nombre único para el archivo de imagen
     */
    fun generateUniqueImageName(originalFilename: String?, imageType: ImageTypeInfo): String {
        val timestamp = System.currentTimeMillis()
        val uuid = UUID.randomUUID().toString().substring(0, 8)
        val extension = imageType.extension

        return if (originalFilename != null) {
            val nameWithoutExt = originalFilename.substringBeforeLast('.')
            "${nameWithoutExt}_${timestamp}_${uuid}.${extension}"
        } else {
            "product_image_${timestamp}_${uuid}.${extension}"
        }
    }

    /**
     * Valida si el tipo de imagen es soportado
     */
    fun isSupportedImageType(imageType: ImageTypeInfo): Boolean {
        return imageType.extension in listOf("jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff")
    }

    /**
     * Construye metadata de la imagen en formato JSON
     */
    fun buildImageMetadata(imageType: ImageTypeInfo, filePart: FilePart, sizeBytes: Int): String {
        val metadata = mapOf(
            "originalFilename" to (filePart.filename() ?: "unknown"),
            "extension" to imageType.extension,
            "format" to imageType.format,
            "mimeType" to imageType.mimeType,
            "sizeBytes" to sizeBytes,
            "detectedAt" to java.time.LocalDateTime.now().toString(),
            "isSupported" to ImageUtils.isSupportedImageType(imageType)
        )

        return try {
            ObjectMapper().writeValueAsString(metadata)
        } catch (e: Exception) {
            "{\"error\": \"Failed to serialize metadata\"}"
        }
    }
}

/**
 * Información del tipo de imagen detectado
 */
data class ImageTypeInfo(
    val extension: String,      // Extensión del archivo (sin punto)
    val format: String,         // Formato de la imagen
    val mimeType: String        // Tipo MIME
)
