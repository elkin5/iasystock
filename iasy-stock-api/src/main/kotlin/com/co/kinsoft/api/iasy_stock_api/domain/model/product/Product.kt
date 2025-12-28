package com.co.kinsoft.api.iasy_stock_api.domain.model.product

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

data class Product(
    val id: Long = 0,
    val name: String,
    val description: String? = null,
    val productImage: ByteArray? = null,
    val imageUrl: String? = null,
    val categoryId: Long,
    val stockQuantity: Int? = null,
    val stockMinimum: Int? = null,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val expirationDate: LocalDate? = null,

    // Campos de vectores de imagen
    var imageEmbedding: Any? = null, // Vector como string base64
    val embeddingModel: String? = null,
    val imageUpdatedAt: LocalDateTime? = null,
    val imageHash: String? = null,
    val embeddingConfidence: BigDecimal? = null,
    val imageMetadata: String? = null,
    val similarityThreshold: BigDecimal? = null,
    val multipleViews: String? = null,
    val imageTags: List<String>? = null,
    val imageQualityScore: BigDecimal? = null,
    val imageFormat: String? = null,
    val imageSizeBytes: Int? = null,

    // Campos auto-extraíbles
    val barcodeData: String? = null,
    val brandName: String? = null,
    val modelNumber: String? = null,
    val dominantColors: String? = null,
    val textOcr: String? = null,
    val logoDetection: String? = null,
    val objectDetection: String? = null,
    val recognitionAccuracy: BigDecimal? = null,
    val lastRecognitionAt: LocalDateTime? = null,
    val recognitionCount: Int? = null,

    // Campos inferidos automáticamente
    val inferredCategory: String? = null,
    val inferredPriceRange: String? = null,
    val inferredUsageTags: List<String>? = null,
    val confidenceScores: String? = null
) {
    fun isValid(): Boolean = name.isNotBlank() && categoryId > 0
    
    fun hasImage(): Boolean = productImage != null || !imageUrl.isNullOrBlank()
    
    fun hasRecognitionData(): Boolean = imageEmbedding != null || !barcodeData.isNullOrBlank() || !brandName.isNullOrBlank()
    
    fun isStockLow(): Boolean = stockQuantity != null && stockMinimum != null && stockQuantity <= stockMinimum
    
    fun getDisplayStock(): String = stockQuantity?.toString() ?: "Sin stock"
    
    fun getDisplayExpiration(): String = expirationDate?.toString() ?: "Sin fecha de expiración"
}