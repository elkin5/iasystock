package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api

import com.co.kinsoft.api.iasy_stock_api.config.MinioProperties
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.net.URI

/**
 * Handler para proxy de imágenes desde MinIO
 *
 * Este handler permite que el frontend acceda a las imágenes de MinIO
 * a través del backend, evitando problemas de CORS y URLs firmadas
 */
@Component
class ImageProxyHandler(
    private val minioProperties: MinioProperties
) {

    private val logger = LoggerFactory.getLogger(ImageProxyHandler::class.java)

    // WebClient configurado para manejar imágenes grandes
    private val webClient: WebClient = WebClient.builder()
        .codecs { configurer ->
            // Aumentar buffer para imágenes grandes (10MB)
            configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024)
        }
        .build()
    
    /**
     * Proxy para imágenes de productos
     * Endpoint: /api/images/proxy?url=<minio-url>
     */
    fun proxyImage(request: ServerRequest): Mono<ServerResponse> {
        val imageUrl = request.queryParam("url")
            .orElse(null)
        
        if (imageUrl == null) {
            return ServerResponse.badRequest()
                .bodyValue(mapOf("error" to "URL parameter is required"))
        }
        
        return try {
            val uri = URI(imageUrl)
            
            // Validar que la URL sea de MinIO
            if (!isValidMinioUrl(uri)) {
                logger.warn("Intento de acceso a URL no autorizada: $imageUrl")
                return ServerResponse.status(HttpStatus.FORBIDDEN)
                    .bodyValue(mapOf("error" to "URL no autorizada"))
            }
            
            logger.debug("Proxy de imagen: $imageUrl")

            // Hacer la petición a MinIO y retornar directamente el body
            webClient.get()
                .uri(uri)
                .retrieve()
                .bodyToMono(ByteArray::class.java)
                .flatMap { imageBytes ->
                    // Determinar content type basado en la extensión del archivo
                    val contentType = determineContentType(uri.path)

                    ServerResponse.ok()
                        .contentType(contentType)
                        .header("Cache-Control", "public, max-age=3600") // Cache por 1 hora
                        .header("Content-Length", imageBytes.size.toString())
                        .bodyValue(imageBytes)
                }
                .onErrorResume { error ->
                    logger.error("Error al obtener imagen desde MinIO: $imageUrl", error)
                    ServerResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .bodyValue(mapOf("error" to "Error al obtener imagen: ${error.message}"))
                }
                
        } catch (e: Exception) {
            logger.error("Error en proxy de imagen: $imageUrl", e)
            ServerResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .bodyValue(mapOf("error" to "Error al obtener imagen: ${e.message}"))
        }
    }
    
    /**
     * Valida que la URL sea de MinIO y esté autorizada
     */
    private fun isValidMinioUrl(uri: URI): Boolean {
        val path = uri.path

        // Obtener el endpoint configurado de MinIO
        val minioEndpoint = try {
            URI(minioProperties.endpoint)
        } catch (e: Exception) {
            logger.error("Error parseando endpoint de MinIO: ${minioProperties.endpoint}", e)
            return false
        }

        // Verificar que el host y puerto coincidan con el endpoint configurado
        if (uri.host?.lowercase() != minioEndpoint.host?.lowercase()) {
            logger.debug("Host no coincide: ${uri.host} != ${minioEndpoint.host}")
            return false
        }

        val minioPort = if (minioEndpoint.port == -1) {
            if (minioEndpoint.scheme == "https") 443 else 80
        } else {
            minioEndpoint.port
        }

        val requestPort = if (uri.port == -1) {
            if (uri.scheme == "https") 443 else 80
        } else {
            uri.port
        }

        if (requestPort != minioPort) {
            logger.debug("Puerto no coincide: $requestPort != $minioPort")
            return false
        }

        // Verificar que sea del bucket de imágenes de productos
        val bucketName = minioProperties.bucket.productImages
        if (!path.startsWith("/$bucketName/")) {
            logger.debug("Path no coincide con bucket: $path no inicia con /$bucketName/")
            return false
        }

        return true
    }
    
    /**
     * Determina el content type basado en la extensión del archivo
     */
    private fun determineContentType(filePath: String): MediaType {
        return when (filePath.lowercase().substringAfterLast('.')) {
            "jpg", "jpeg" -> MediaType.IMAGE_JPEG
            "png" -> MediaType.IMAGE_PNG
            "gif" -> MediaType.IMAGE_GIF
            "webp" -> MediaType.parseMediaType("image/webp")
            "svg" -> MediaType.parseMediaType("image/svg+xml")
            else -> MediaType.APPLICATION_OCTET_STREAM
        }
    }
}
