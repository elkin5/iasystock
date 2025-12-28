package com.co.kinsoft.api.iasy_stock_api.domain.model.filestorage

import reactor.core.publisher.Mono

/**
 * Puerto (interface) del dominio para el manejo de archivos
 * Siguiendo los principios de Arquitectura Limpia
 */
interface FileStorageService {
    
    /**
     * Sube una imagen de producto al sistema de almacenamiento
     * @param imageBytes Bytes de la imagen a subir
     * @param originalFileName Nombre original del archivo (opcional)
     * @param contentType Tipo de contenido (por defecto image/jpeg)
     * @return URL pública para acceder a la imagen
     */
    fun uploadProductImage(
        imageBytes: ByteArray,
        originalFileName: String? = null,
        imageFormat: String = "jpeg"
    ): Mono<String>
    
    /**
     * Elimina una imagen del sistema de almacenamiento
     * @param imageUrl URL de la imagen a eliminar
     * @return Completable que indica éxito o error
     */
    fun deleteProductImage(imageUrl: String): Mono<Void>
    
    /**
     * Genera una URL firmada para acceso temporal a la imagen
     * @param imageUrl URL de la imagen
     * @return URL firmada con acceso temporal
     */
    fun generatePresignedUrl(imageUrl: String): Mono<String>
    
    /**
     * Verifica si una imagen existe en el sistema de almacenamiento
     * @param imageUrl URL de la imagen a verificar
     * @return true si existe, false si no
     */
    fun imageExists(imageUrl: String): Mono<Boolean>
}

/**
 * Resultado de la operación de subida de imagen
 */
data class ImageUploadResult(
    val imageUrl: String,
    val fileName: String,
    val contentType: String,
    val sizeBytes: Long
)

/**
 * Excepción específica para operaciones de almacenamiento de archivos
 */
class FileStorageException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)
