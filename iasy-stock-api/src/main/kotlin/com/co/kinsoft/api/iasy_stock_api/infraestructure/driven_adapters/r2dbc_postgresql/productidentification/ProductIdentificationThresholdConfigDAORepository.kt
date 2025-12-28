package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import org.springframework.data.r2dbc.repository.Query
import org.springframework.data.r2dbc.repository.R2dbcRepository
import org.springframework.data.repository.query.Param
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

/**
 * Repositorio R2DBC para ProductIdentificationThresholdConfigDAO
 */
interface ProductIdentificationThresholdConfigDAORepository : R2dbcRepository<ProductIdentificationThresholdConfigDAO, Long> {

    /**
     * Obtiene la configuración activa
     */
    fun findByIsActive(isActive: Boolean): Mono<ProductIdentificationThresholdConfigDAO>

    /**
     * Obtiene la configuración activa más reciente
     */
    @Query("""
        SELECT * FROM schmain.product_identification_threshold_config
        WHERE is_active = true
        ORDER BY created_at DESC
        LIMIT 1
    """)
    fun findActiveConfig(): Mono<ProductIdentificationThresholdConfigDAO>

    /**
     * Obtiene configuración por versión de modelo
     */
    fun findByModelVersion(modelVersion: String): Mono<ProductIdentificationThresholdConfigDAO>

    /**
     * Obtiene todas las configuraciones ordenadas por fecha
     */
    @Query("""
        SELECT * FROM schmain.product_identification_threshold_config
        ORDER BY created_at DESC
    """)
    fun findAllOrderedByDate(): Flux<ProductIdentificationThresholdConfigDAO>

    /**
     * Obtiene el historial de configuraciones (últimas N)
     */
    @Query("""
        SELECT * FROM schmain.product_identification_threshold_config
        ORDER BY created_at DESC
        LIMIT :limit
    """)
    fun findConfigHistory(@Param("limit") limit: Int): Flux<ProductIdentificationThresholdConfigDAO>

    /**
     * Desactiva todas las configuraciones excepto la especificada
     */
    @Query("""
        UPDATE schmain.product_identification_threshold_config
        SET is_active = false, updated_at = NOW()
        WHERE config_id != :configId AND is_active = true
    """)
    fun deactivateAllExcept(@Param("configId") configId: Long): Mono<Long>

    /**
     * Activa una configuración específica
     */
    @Query("""
        UPDATE schmain.product_identification_threshold_config
        SET is_active = true, updated_at = NOW()
        WHERE config_id = :configId
    """)
    fun activateConfig(@Param("configId") configId: Long): Mono<Long>

    /**
     * Obtiene configuraciones con accuracy mayor a un valor
     */
    @Query("""
        SELECT * FROM schmain.product_identification_threshold_config
        WHERE accuracy IS NOT NULL AND accuracy >= :minAccuracy
        ORDER BY accuracy DESC
    """)
    fun findByMinAccuracy(@Param("minAccuracy") minAccuracy: Double): Flux<ProductIdentificationThresholdConfigDAO>

    /**
     * Obtiene la mejor configuración (mayor accuracy)
     */
    @Query("""
        SELECT * FROM schmain.product_identification_threshold_config
        WHERE accuracy IS NOT NULL
        ORDER BY accuracy DESC
        LIMIT 1
    """)
    fun findBestConfig(): Mono<ProductIdentificationThresholdConfigDAO>

    /**
     * Obtiene todas las configuraciones ordenadas por accuracy (mayor a menor)
     */
    @Query("""
        SELECT * FROM schmain.product_identification_threshold_config
        WHERE accuracy IS NOT NULL
        ORDER BY accuracy DESC, created_at DESC
    """)
    fun findAllOrderedByAccuracy(): Flux<ProductIdentificationThresholdConfigDAO>
}
