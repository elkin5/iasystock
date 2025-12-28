package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal
import java.time.LocalDateTime

/**
 * DAO para la tabla product_identification_validation
 */
@Table("product_identification_validation")
data class ProductIdentificationValidationDAO(
    @Id
    @Column("validation_id")
    val validationId: Long? = null,

    // Información de la imagen procesada
    @Column("image_hash")
    val imageHash: String,

    @Column("image_url")
    val imageUrl: String? = null,

    @Column("image_embedding")
    val imageEmbedding: String? = null,

    // Productos involucrados
    @Column("suggested_product_id")
    val suggestedProductId: Long? = null,

    @Column("actual_product_id")
    val actualProductId: Long? = null,

    // Métricas de identificación
    @Column("confidence_score")
    val confidenceScore: BigDecimal,

    @Column("match_type")
    val matchType: String,

    @Column("similarity_score")
    val similarityScore: BigDecimal? = null,

    // Resultado de validación
    @Column("was_correct")
    val wasCorrect: Boolean,

    @Column("correction_type")
    val correctionType: String,

    // Auditoría
    @Column("validated_by")
    val validatedBy: Long,

    @Column("validated_at")
    val validatedAt: LocalDateTime = LocalDateTime.now(),

    @Column("feedback_notes")
    val feedbackNotes: String? = null,

    // Contexto de uso
    @Column("validation_source")
    val validationSource: String,

    @Column("related_sale_id")
    val relatedSaleId: Long? = null,

    @Column("related_stock_id")
    val relatedStockId: Long? = null,

    // Metadatos
    @Column("metadata")
    val metadata: String? = null,

    @Column("created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column("updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
