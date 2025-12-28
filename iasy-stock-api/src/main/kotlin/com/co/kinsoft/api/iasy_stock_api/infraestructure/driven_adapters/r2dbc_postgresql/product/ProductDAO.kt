package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.product

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

@Table("Product", schema = "schmain")
data class ProductDAO(
    @Id
    @Column("product_id")
    var id: Long? = 0,

    @Column("name")
    var name: String = "",

    @Column("description")
    var description: String? = null,

    @Column("product_image")
    var productImage: ByteArray? = null,

    @Column("image_url")
    var imageUrl: String? = null,

    @Column("category_id")
    var categoryId: Long,

    @Column("stock_quantity")
    var stockQuantity: Int? = null,

    @Column("stock_minimum")
    var stockMinimum: Int? = null,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column("expiration_date")
    var expirationDate: LocalDate? = null,

    // Campos de vectores de imagen
    @Column("image_embedding")
    var imageEmbedding: Any? = null,

    @Column("embedding_model")
    var embeddingModel: String? = null,

    @Column("image_updated_at")
    var imageUpdatedAt: LocalDateTime? = null,

    @Column("image_hash")
    var imageHash: String? = null,

    @Column("embedding_confidence")
    var embeddingConfidence: BigDecimal? = null,

    @Column("image_metadata")
    var imageMetadata: String? = null,

    @Column("similarity_threshold")
    var similarityThreshold: BigDecimal? = null,

    @Column("multiple_views")
    var multipleViews: String? = null,

    @Column("image_tags")
    var imageTags: List<String>? = null,

    @Column("image_quality_score")
    var imageQualityScore: BigDecimal? = null,

    @Column("image_format")
    var imageFormat: String? = null,

    @Column("image_size_bytes")
    var imageSizeBytes: Int? = null,

    // Campos auto-extraíbles
    @Column("barcode_data")
    var barcodeData: String? = null,

    @Column("brand_name")
    var brandName: String? = null,

    @Column("model_number")
    var modelNumber: String? = null,

    @Column("dominant_colors")
    var dominantColors: String? = null,

    @Column("text_ocr")
    var textOcr: String? = null,

    @Column("logo_detection")
    var logoDetection: String? = null,

    @Column("object_detection")
    var objectDetection: String? = null,

    @Column("recognition_accuracy")
    var recognitionAccuracy: BigDecimal? = null,

    @Column("last_recognition_at")
    var lastRecognitionAt: LocalDateTime? = null,

    @Column("recognition_count")
    var recognitionCount: Int? = null,

    // Campos inferidos automáticamente
    @Column("inferred_category")
    var inferredCategory: String? = null,

    @Column("inferred_price_range")
    var inferredPriceRange: String? = null,

    @Column("inferred_usage_tags")
    var inferredUsageTags: List<String>? = null,

    @Column("confidence_scores")
    var confidenceScores: String? = null
)