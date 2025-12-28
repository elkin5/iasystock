package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.minio

import com.co.kinsoft.api.iasy_stock_api.config.MinioProperties
import com.co.kinsoft.api.iasy_stock_api.domain.model.filestorage.FileStorageService
import com.co.kinsoft.api.iasy_stock_api.domain.model.filestorage.FileStorageException
import io.minio.*
import io.minio.errors.ErrorResponseException
import io.minio.http.Method
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import reactor.core.scheduler.Schedulers
import java.io.ByteArrayInputStream
import java.security.MessageDigest
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*
import java.util.concurrent.TimeUnit

@Service
class MinioFileService(
    private val minioClient: MinioClient,
    private val minioProperties: MinioProperties
) : FileStorageService {
    
    private val logger = LoggerFactory.getLogger(MinioFileService::class.java)

    /**
     * Sube una imagen al bucket de MinIO y retorna la URL de acceso
     * Implementación del puerto FileStorageService del dominio
     */
    override fun uploadProductImage(
        imageBytes: ByteArray,
        originalFileName: String?,
        imageFormat: String
    ): Mono<String> {
        return Mono.fromCallable {
            val bucketName = minioProperties.bucket.productImages
            val contentType = "image/${imageFormat ?: "jpeg"}"
            
            // ✅ VALIDAR ARCHIVO SEGÚN CONFIGURACIONES DE SEGURIDAD
            validateFileUpload(imageBytes, contentType)
            
            // Crear bucket si no existe
            ensureBucketExists(bucketName)
            
            // Generar nombre único para el archivo
            val fileName = generateUniqueFileName(imageBytes, originalFileName, imageFormat)
            
            // Subir archivo
            val putObjectArgs = PutObjectArgs.builder()
                .bucket(bucketName)
                .`object`(fileName)
                .stream(ByteArrayInputStream(imageBytes), imageBytes.size.toLong(), -1)
                .contentType(contentType)
                .build()
            
            val result = minioClient.putObject(putObjectArgs)
            
            logger.info("Imagen subida exitosamente: bucket=$bucketName, object=$fileName, etag=${result.etag()}, size=${imageBytes.size} bytes")
            
            // Retornar URL de acceso (ahora genera URL firmada)
            generateImageUrl(bucketName, fileName)
            
        }.subscribeOn(Schedulers.boundedElastic())
        .doOnError { error ->
            logger.error("Error al subir imagen a MinIO", error)
        }
        .onErrorMap { error ->
            when (error) {
                is ErrorResponseException -> {
                    FileStorageException("Error al subir imagen: ${error.errorResponse().message()}")
                }
                else -> FileStorageException("Error inesperado al subir imagen: ${error.message}")
            }
        }
    }

    /**
     * Elimina una imagen del bucket usando la URL
     */
    override fun deleteProductImage(imageUrl: String): Mono<Void> {
        return Mono.fromRunnable<Void> {
            val bucketName = minioProperties.bucket.productImages
            val fileName = extractFileNameFromUrl(imageUrl)
            
            if (fileName != null) {
                val removeObjectArgs = RemoveObjectArgs.builder()
                    .bucket(bucketName)
                    .`object`(fileName)
                    .build()
                
                minioClient.removeObject(removeObjectArgs)
                logger.info("Imagen eliminada exitosamente: bucket=$bucketName, object=$fileName")
            }
        }.subscribeOn(Schedulers.boundedElastic())
        .doOnError { error ->
            logger.error("Error al eliminar imagen de MinIO", error)
        }
        .onErrorMap { error ->
            FileStorageException("Error al eliminar imagen: ${error.message}")
        }
    }

    /**
     * Genera una URL firmada para acceso temporal a la imagen
     * Usa configuraciones de seguridad para determinar tiempo de expiración
     */
    override fun generatePresignedUrl(imageUrl: String): Mono<String> {
        return Mono.fromCallable {
            // Extraer la URL original de MinIO, evitando URLs de proxy anidadas
            val originalMinioUrl = extractOriginalMinioUrl(imageUrl)
            
            val bucketName = minioProperties.bucket.productImages
            val fileName = extractFileNameFromUrl(originalMinioUrl)
                ?: throw FileStorageException("No se pudo extraer el nombre del archivo de la URL")
            
            val expiryHours = minioProperties.security.defaultExpiryHours.toInt()
            
            val getPresignedObjectUrlArgs = GetPresignedObjectUrlArgs.builder()
                .method(Method.GET)
                .bucket(bucketName)
                .`object`(fileName)
                .expiry(expiryHours, TimeUnit.HOURS)
                .build()
            
            val presignedUrl = minioClient.getPresignedObjectUrl(getPresignedObjectUrlArgs)
            
            logger.debug("URL firmada regenerada para $fileName, válida por $expiryHours horas")

            // Usar proxy para evitar problemas de CORS y URLs firmadas
            val baseUrl = minioProperties.apiBaseUrl
            val proxyUrl = "$baseUrl/api/images/proxy?url=${java.net.URLEncoder.encode(presignedUrl, "UTF-8")}"

            proxyUrl
            
        }.subscribeOn(Schedulers.boundedElastic())
        .doOnError { error ->
            logger.error("Error al generar URL firmada", error)
        }
        .onErrorMap { error ->
            FileStorageException("Error al generar URL firmada: ${error.message}")
        }
    }

    /**
     * Verifica si una imagen existe en el bucket
     */
    override fun imageExists(imageUrl: String): Mono<Boolean> {
        return Mono.fromCallable {
            val bucketName = minioProperties.bucket.productImages
            val fileName = extractFileNameFromUrl(imageUrl)
            
            if (fileName == null) return@fromCallable false
            
            try {
                val statObjectArgs = StatObjectArgs.builder()
                    .bucket(bucketName)
                    .`object`(fileName)
                    .build()
                
                minioClient.statObject(statObjectArgs)
                true
            } catch (e: ErrorResponseException) {
                if (e.errorResponse().code() == "NoSuchKey") {
                    false
                } else {
                    throw e
                }
            }
        }.subscribeOn(Schedulers.boundedElastic())
        .onErrorReturn(false)
    }

    /**
     * Asegura que el bucket existe, si no lo crea
     */
    private fun ensureBucketExists(bucketName: String) {
        val bucketExistsArgs = BucketExistsArgs.builder()
            .bucket(bucketName)
            .build()
        
        val exists = minioClient.bucketExists(bucketExistsArgs)
        
        if (!exists) {
            val makeBucketArgs = MakeBucketArgs.builder()
                .bucket(bucketName)
                .region(minioProperties.region)
                .build()
            
            minioClient.makeBucket(makeBucketArgs)
            logger.info("Bucket creado: $bucketName")
        }
    }

    /**
     * Genera un nombre único para el archivo basado en hash MD5 y timestamp
     */
    private fun generateUniqueFileName(imageBytes: ByteArray, originalFileName: String?, imageFormat: String): String {
        val md5 = MessageDigest.getInstance("MD5")
        val hash = md5.digest(imageBytes)
        val hashString = hash.joinToString("") { "%02x".format(it) }
        
        val timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))
        val extension = originalFileName?.substringAfterLast('.', imageFormat) ?: imageFormat
        
        return "product_${timestamp}_${hashString.substring(0, 8)}.${extension}"
    }

    /**
     * Genera una URL firmada temporal para acceso seguro a la imagen
     * CAMBIO DE SEGURIDAD: URLs firmadas en lugar de URLs públicas directas
     */
    private fun generateImageUrl(bucketName: String, fileName: String): String {
        // ✅ SEGURO: Usar configuración de seguridad para URLs firmadas
        val expiryHours = minioProperties.security.defaultExpiryHours.toInt()
        
        val getPresignedObjectUrlArgs = GetPresignedObjectUrlArgs.builder()
            .method(Method.GET)
            .bucket(bucketName)
            .`object`(fileName)
            .expiry(expiryHours, TimeUnit.HOURS)
            .build()
        
        val presignedUrl = minioClient.getPresignedObjectUrl(getPresignedObjectUrlArgs)
        
        logger.debug("URL firmada generada para $fileName, válida por $expiryHours horas")

        // Usar proxy para evitar problemas de CORS y URLs firmadas
        val baseUrl = minioProperties.apiBaseUrl
        val proxyUrl = "$baseUrl/api/images/proxy?url=${java.net.URLEncoder.encode(presignedUrl, "UTF-8")}"

        return proxyUrl
    }

    /**
     * Valida el archivo antes de subirlo según las configuraciones de seguridad
     */
    private fun validateFileUpload(imageBytes: ByteArray, contentType: String) {
        // Validar tamaño del archivo
        val fileSizeBytes = imageBytes.size
        val maxFileSizeBytes = minioProperties.security.maxFileSizeMb * 1024 * 1024
        
        if (fileSizeBytes > maxFileSizeBytes) {
            throw FileStorageException(
                "Archivo demasiado grande: ${fileSizeBytes / 1024 / 1024}MB. " +
                "Tamaño máximo permitido: ${minioProperties.security.maxFileSizeMb}MB"
            )
        }
        
        // Validar tipo de contenido
        val normalizedContentType = contentType.lowercase()
        val allowedTypes = minioProperties.security.allowedContentTypes.map { it.lowercase() }
        
        if (!allowedTypes.contains(normalizedContentType)) {
            throw FileStorageException(
                "Tipo de archivo no permitido: $contentType. " +
                "Tipos permitidos: ${minioProperties.security.allowedContentTypes.joinToString(", ")}"
            )
        }
        
        logger.debug("Archivo validado: size=${fileSizeBytes}bytes, contentType=$contentType")
    }

    /**
     * Extrae la URL original de MinIO de una URL de proxy anidada
     */
    private fun extractOriginalMinioUrl(imageUrl: String): String {
        // Si la URL ya es una URL directa de MinIO, devolverla tal como está
        if (!imageUrl.contains("/api/images/proxy?url=")) {
            return imageUrl
        }
        
        try {
            // Decodificar la URL del proxy
            val decodedUrl = java.net.URLDecoder.decode(imageUrl, "UTF-8")
            
            // Extraer la URL después del parámetro url=
            val urlParam = decodedUrl.substringAfter("url=")
            
            // Decodificar nuevamente si es necesario
            return java.net.URLDecoder.decode(urlParam, "UTF-8")
            
        } catch (e: Exception) {
            logger.warn("Error extrayendo URL original de MinIO: $imageUrl", e)
            return imageUrl
        }
    }

    /**
     * Extrae el nombre del archivo de una URL de MinIO (incluyendo URLs firmadas)
     */
    private fun extractFileNameFromUrl(imageUrl: String): String? {
        return try {
            val bucketName = minioProperties.bucket.productImages
            val expectedPrefix = "${minioProperties.endpoint}/$bucketName/"
            
            if (imageUrl.startsWith(expectedPrefix)) {
                // Para URLs firmadas, remover parámetros de consulta
                val urlWithoutParams = imageUrl.substringBefore('?')
                urlWithoutParams.substring(expectedPrefix.length)
            } else {
                // Intentar extraer solo el nombre del archivo de la URL
                val urlWithoutParams = imageUrl.substringBefore('?')
                urlWithoutParams.substringAfterLast('/')
            }
        } catch (e: Exception) {
            logger.warn("Error al extraer nombre de archivo de URL: $imageUrl", e)
            null
        }
    }
}
