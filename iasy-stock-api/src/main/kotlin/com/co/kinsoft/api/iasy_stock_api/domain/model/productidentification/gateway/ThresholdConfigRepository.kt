package com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.IdentificationThresholdConfig
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

/**
 * Gateway para repositorio de configuraciones de umbrales
 * (Arquitectura Hexagonal - Puerto)
 */
interface ThresholdConfigRepository {

    /**
     * Guarda una configuración de umbrales
     */
    fun save(config: IdentificationThresholdConfig): Mono<IdentificationThresholdConfig>

    /**
     * Busca configuración por ID
     */
    fun findById(configId: Long): Mono<IdentificationThresholdConfig>

    /**
     * Obtiene la configuración activa
     */
    fun getActiveConfig(): Mono<IdentificationThresholdConfig>

    /**
     * Busca todas las configuraciones
     */
    fun findAll(): Flux<IdentificationThresholdConfig>

    /**
     * Busca configuraciones por versión del modelo
     */
    fun findByModelVersion(modelVersion: String): Flux<IdentificationThresholdConfig>

    /**
     * Busca configuraciones activas
     */
    fun findActiveConfigs(): Flux<IdentificationThresholdConfig>

    /**
     * Desactiva todas las configuraciones excepto una
     */
    fun deactivateAllExcept(configId: Long): Mono<Void>

    /**
     * Busca la mejor configuración (mayor accuracy)
     */
    fun findBestConfig(): Mono<IdentificationThresholdConfig>

    /**
     * Busca configuraciones ordenadas por accuracy
     */
    fun findAllOrderedByAccuracy(): Flux<IdentificationThresholdConfig>

    /**
     * Elimina configuración por ID
     */
    fun deleteById(configId: Long): Mono<Void>

    /**
     * Activa una configuración y desactiva las demás
     */
    fun activateConfig(configId: Long): Mono<IdentificationThresholdConfig>
}
