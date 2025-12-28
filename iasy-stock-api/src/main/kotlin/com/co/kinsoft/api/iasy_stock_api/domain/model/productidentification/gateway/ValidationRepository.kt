package com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ProductIdentificationValidation
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Gateway para repositorio de validaciones de identificación
 * (Arquitectura Hexagonal - Puerto)
 */
interface ValidationRepository {

    /**
     * Guarda una validación
     */
    fun save(validation: ProductIdentificationValidation): Mono<ProductIdentificationValidation>

    /**
     * Busca validación por ID
     */
    fun findById(validationId: Long): Mono<ProductIdentificationValidation>

    /**
     * Busca todas las validaciones
     */
    fun findAll(): Flux<ProductIdentificationValidation>

    /**
     * Busca validaciones por hash de imagen
     */
    fun findByImageHash(imageHash: String): Flux<ProductIdentificationValidation>

    /**
     * Busca validaciones por producto sugerido
     */
    fun findBySuggestedProductId(suggestedProductId: Long): Flux<ProductIdentificationValidation>

    /**
     * Busca validaciones por tipo de match
     */
    fun findByMatchType(matchType: String): Flux<ProductIdentificationValidation>

    /**
     * Busca validaciones por fuente
     */
    fun findByValidationSource(validationSource: String): Flux<ProductIdentificationValidation>

    /**
     * Busca validaciones en rango de fechas
     */
    fun findByValidatedAtBetween(startDate: LocalDateTime, endDate: LocalDateTime): Flux<ProductIdentificationValidation>

    /**
     * Cuenta validaciones desde último entrenamiento
     */
    fun countValidationsSinceLastTraining(): Mono<Long>

    /**
     * Obtiene validaciones recientes
     */
    fun findRecentValidations(limit: Int): Flux<ProductIdentificationValidation>

    /**
     * Obtiene validaciones recientes por tipo de match
     */
    fun findRecentValidationsByMatchType(matchType: String, limit: Int): Flux<ProductIdentificationValidation>

    /**
     * Cuenta false positives
     */
    fun countFalsePositives(): Mono<Long>

    /**
     * Cuenta false negatives
     */
    fun countFalseNegatives(): Mono<Long>

    /**
     * Elimina validación por ID
     */
    fun deleteById(validationId: Long): Mono<Void>
}
