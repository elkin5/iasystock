package com.co.kinsoft.api.iasy_stock_api.utils

import com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.product.utils.ImageTypeInfo
import com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.product.utils.ImageUtils
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class ImageUtilsTest {

    @Test
    fun `debe detectar correctamente una imagen JPEG`() {
        // Simular bytes de una imagen JPEG (magic numbers)
        val jpegBytes = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte())
        
        val result = ImageUtils.detectImageType(jpegBytes)
        
        assertEquals("jpg", result.extension)
        assertEquals("jpeg", result.format)
        assertEquals("image/jpeg", result.mimeType)
        assertTrue(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe detectar correctamente una imagen PNG`() {
        // Simular bytes de una imagen PNG (magic numbers)
        val pngBytes = byteArrayOf(0x89.toByte(), 0x50.toByte(), 0x4E.toByte(), 0x47.toByte())
        
        val result = ImageUtils.detectImageType(pngBytes)
        
        assertEquals("png", result.extension)
        assertEquals("png", result.format)
        assertEquals("image/png", result.mimeType)
        assertTrue(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe detectar correctamente una imagen GIF`() {
        // Simular bytes de una imagen GIF (magic numbers)
        val gifBytes = byteArrayOf(0x47.toByte(), 0x49.toByte(), 0x46.toByte(), 0x38.toByte())
        
        val result = ImageUtils.detectImageType(gifBytes)
        
        assertEquals("gif", result.extension)
        assertEquals("gif", result.format)
        assertEquals("image/gif", result.mimeType)
        assertTrue(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe detectar correctamente una imagen WebP`() {
        // Simular bytes de una imagen WebP (magic numbers)
        val webpBytes = byteArrayOf(
            0x52.toByte(), 0x49.toByte(), 0x46.toByte(), 0x46.toByte(), // RIFF
            0x00.toByte(), 0x00.toByte(), 0x00.toByte(), 0x00.toByte(), // tamaño
            0x57.toByte(), 0x45.toByte(), 0x42.toByte(), 0x50.toByte()  // WEBP
        )
        
        val result = ImageUtils.detectImageType(webpBytes)
        
        assertEquals("webp", result.extension)
        assertEquals("webp", result.format)
        assertEquals("image/webp", result.mimeType)
        assertTrue(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe detectar correctamente una imagen BMP`() {
        // Simular bytes de una imagen BMP (magic numbers)
        val bmpBytes = byteArrayOf(0x42.toByte(), 0x4D.toByte(), 0x00.toByte(), 0x00.toByte())
        
        val result = ImageUtils.detectImageType(bmpBytes)
        
        assertEquals("bmp", result.extension)
        assertEquals("bmp", result.format)
        assertEquals("image/bmp", result.mimeType)
        assertTrue(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe detectar correctamente una imagen TIFF`() {
        // Simular bytes de una imagen TIFF (magic numbers - little endian)
        val tiffBytes = byteArrayOf(0x49.toByte(), 0x49.toByte(), 0x2A.toByte(), 0x00.toByte())
        
        val result = ImageUtils.detectImageType(tiffBytes)
        
        assertEquals("tiff", result.extension)
        assertEquals("tiff", result.format)
        assertEquals("image/tiff", result.mimeType)
        assertTrue(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe retornar unknown para bytes no reconocidos`() {
        val unknownBytes = byteArrayOf(0x00.toByte(), 0x01.toByte(), 0x02.toByte(), 0x03.toByte())
        
        val result = ImageUtils.detectImageType(unknownBytes)
        
        assertEquals("unknown", result.extension)
        assertEquals("unknown", result.format)
        assertEquals("application/octet-stream", result.mimeType)
        assertFalse(ImageUtils.isSupportedImageType(result))
    }

    @Test
    fun `debe generar nombre único para imagen`() {
        val imageType = ImageTypeInfo("jpg", "jpeg", "image/jpeg")
        val originalFilename = "test_image.jpg"
        
        val result = ImageUtils.generateUniqueImageName(originalFilename, imageType)
        
        assertTrue(result.startsWith("test_image_"))
        assertTrue(result.endsWith(".jpg"))
        assertTrue(result.contains("_")) // Debe contener timestamp y UUID
    }

    @Test
    fun `debe generar nombre único para imagen sin nombre original`() {
        val imageType = ImageTypeInfo("png", "png", "image/png")
        
        val result = ImageUtils.generateUniqueImageName(null, imageType)
        
        assertTrue(result.startsWith("product_image_"))
        assertTrue(result.endsWith(".png"))
        assertTrue(result.contains("_")) // Debe contener timestamp y UUID
    }

    @Test
    fun `debe validar tipos de imagen soportados`() {
        val supportedTypes = listOf(
            ImageTypeInfo("jpg", "jpeg", "image/jpeg"),
            ImageTypeInfo("png", "png", "image/png"),
            ImageTypeInfo("gif", "gif", "image/gif"),
            ImageTypeInfo("webp", "webp", "image/webp"),
            ImageTypeInfo("bmp", "bmp", "image/bmp"),
            ImageTypeInfo("tiff", "tiff", "image/tiff")
        )
        
        supportedTypes.forEach { type ->
            assertTrue(ImageUtils.isSupportedImageType(type), "Tipo ${type.format} debería ser soportado")
        }
    }

    @Test
    fun `debe rechazar tipos de imagen no soportados`() {
        val unsupportedTypes = listOf(
            ImageTypeInfo("unknown", "unknown", "application/octet-stream"),
            ImageTypeInfo("svg", "svg", "image/svg+xml"),
            ImageTypeInfo("ico", "ico", "image/x-icon")
        )
        
        unsupportedTypes.forEach { type ->
            assertFalse(ImageUtils.isSupportedImageType(type), "Tipo ${type.format} no debería ser soportado")
        }
    }
}

