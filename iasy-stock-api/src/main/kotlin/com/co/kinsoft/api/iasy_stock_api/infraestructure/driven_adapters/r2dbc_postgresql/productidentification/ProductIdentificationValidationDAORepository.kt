package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import org.springframework.data.r2dbc.repository.Query
import org.springframework.data.r2dbc.repository.R2dbcRepository
import org.springframework.data.repository.query.Param
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Repositorio R2DBC para ProductIdentificationValidationDAO
 */
interface ProductIdentificationValidationDAORepository : R2dbcRepository<ProductIdentificationValidationDAO, Long> {

    /**
     * Busca validaciones por hash de imagen
     */
    fun findByImageHash(imageHash: String): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones por producto sugerido
     */
    fun findBySuggestedProductId(suggestedProductId: Long): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones por producto actual
     */
    fun findByActualProductId(actualProductId: Long): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones por tipo de match
     */
    fun findByMatchType(matchType: String): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones por fuente
     */
    fun findByValidationSource(validationSource: String): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones por usuario validador
     */
    fun findByValidatedBy(validatedBy: Long): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones correctas/incorrectas
     */
    fun findByWasCorrect(wasCorrect: Boolean): Flux<ProductIdentificationValidationDAO>

    /**
     * Busca validaciones en un rango de fechas
     */
    @Query("""
        SELECT * FROM schmain.product_identification_validation
        WHERE validated_at >= :startDate AND validated_at <= :endDate
        ORDER BY validated_at DESC
    """)
    fun findByValidatedAtBetween(
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Flux<ProductIdentificationValidationDAO>

    /**
     * Cuenta validaciones desde la última fecha de entrenamiento
     */
    @Query("""
        SELECT COUNT(*) FROM schmain.product_identification_validation v
        WHERE v.validated_at > COALESCE(
            (SELECT MAX(last_training_at)
             FROM schmain.product_identification_threshold_config
             WHERE last_training_at IS NOT NULL),
            '1970-01-01'::timestamp
        )
    """)
    fun countValidationsSinceLastTraining(): Mono<Long>

    /**
     * Obtiene las N validaciones más recientes
     */
    @Query("""
        SELECT * FROM schmain.product_identification_validation
        ORDER BY validated_at DESC
        LIMIT :limit
    """)
    fun findRecentValidations(@Param("limit") limit: Int): Flux<ProductIdentificationValidationDAO>

    /**
     * Obtiene validaciones recientes por tipo de match
     */
    @Query("""
        SELECT * FROM schmain.product_identification_validation
        WHERE match_type = :matchType
        ORDER BY validated_at DESC
        LIMIT :limit
    """)
    fun findRecentValidationsByMatchType(
        @Param("matchType") matchType: String,
        @Param("limit") limit: Int
    ): Flux<ProductIdentificationValidationDAO>

    /**
     * Calcula accuracy por tipo de match
     */
    @Query("""
        SELECT
            match_type,
            COUNT(*) as total,
            SUM(CASE WHEN was_correct THEN 1 ELSE 0 END) as correct,
            AVG(CASE WHEN was_correct THEN 1.0 ELSE 0.0 END) as accuracy,
            AVG(confidence_score) as avg_confidence
        FROM schmain.product_identification_validation
        WHERE validated_at > :since
        GROUP BY match_type
    """)
    fun calculateAccuracyByMatchType(@Param("since") since: LocalDateTime): Flux<Map<String, Any>>

    /**
     * Cuenta false positives (identificados incorrectamente como existentes)
     */
    @Query("""
        SELECT COUNT(*) FROM schmain.product_identification_validation
        WHERE was_correct = false
          AND suggested_product_id IS NOT NULL
          AND actual_product_id IS NOT NULL
          AND suggested_product_id != actual_product_id
    """)
    fun countFalsePositives(): Mono<Long>

    /**
     * Cuenta false negatives (no identificados cuando sí existían)
     */
    @Query("""
        SELECT COUNT(*) FROM schmain.product_identification_validation
        WHERE was_correct = false
          AND suggested_product_id IS NULL
          AND actual_product_id IS NOT NULL
    """)
    fun countFalseNegatives(): Mono<Long>
}
