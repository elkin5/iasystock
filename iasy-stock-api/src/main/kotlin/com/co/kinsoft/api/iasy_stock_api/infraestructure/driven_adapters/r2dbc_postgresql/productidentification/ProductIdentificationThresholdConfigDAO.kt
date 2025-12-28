package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal
import java.time.LocalDateTime

/**
 * DAO para la tabla product_identification_threshold_config
 */
@Table("product_identification_threshold_config")
data class ProductIdentificationThresholdConfigDAO(
    @Id
    @Column("config_id")
    val configId: Long? = null,

    // Umbrales por tipo de match
    @Column("barcode_min_confidence")
    val barcodeMinConfidence: BigDecimal = BigDecimal("0.95"),

    @Column("hash_min_confidence")
    val hashMinConfidence: BigDecimal = BigDecimal("1.0"),

    @Column("brand_model_min_confidence")
    val brandModelMinConfidence: BigDecimal = BigDecimal("0.85"),

    @Column("vector_similarity_min_confidence")
    val vectorSimilarityMinConfidence: BigDecimal = BigDecimal("0.75"),

    @Column("tag_category_min_confidence")
    val tagCategoryMinConfidence: BigDecimal = BigDecimal("0.60"),

    // Umbral para auto-aprobar sin validación humana
    @Column("auto_approve_threshold")
    val autoApproveThreshold: BigDecimal = BigDecimal("0.95"),

    // Umbral para requerir validación manual
    @Column("manual_validation_threshold")
    val manualValidationThreshold: BigDecimal = BigDecimal("0.75"),

    // Métricas de rendimiento
    @Column("total_identifications")
    val totalIdentifications: Int = 0,

    @Column("correct_identifications")
    val correctIdentifications: Int = 0,

    @Column("false_positives")
    val falsePositives: Int = 0,

    @Column("false_negatives")
    val falseNegatives: Int = 0,

    @Column("accuracy")
    val accuracy: BigDecimal? = null,

    // Información de entrenamiento
    @Column("last_training_at")
    val lastTrainingAt: LocalDateTime? = null,

    @Column("training_samples_count")
    val trainingSamplesCount: Int = 0,

    @Column("model_version")
    val modelVersion: String = "1.0",

    // Control de versión
    @Column("is_active")
    val isActive: Boolean = true,

    @Column("created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column("updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column("created_by")
    val createdBy: Long? = null,

    // Metadatos
    @Column("notes")
    val notes: String? = null,

    @Column("metadata")
    val metadata: String? = null
)
