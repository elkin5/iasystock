package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ProductIdentificationValidation
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ValidationRepository
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Adaptador de repositorio para validaciones de identificación de productos
 * Implementa el puerto ValidationRepository usando R2DBC PostgreSQL
 * (Arquitectura Hexagonal - Adaptador)
 */
@Repository
class ValidationRepositoryAdapter(
    private val validationDAORepository: ProductIdentificationValidationDAORepository
) : ValidationRepository {

    private val logger: Logger = LoggerFactory.getLogger(ValidationRepositoryAdapter::class.java)

    override fun save(validation: ProductIdentificationValidation): Mono<ProductIdentificationValidation> {
        logger.debug("Guardando validación para imageHash: ${validation.imageHash}")

        return Mono.just(validation)
            .map { it.toDAO() }
            .flatMap { validationDAORepository.save(it) }
            .map { it.toDomain() }
            .doOnSuccess { saved ->
                logger.info("✅ Validación guardada con ID: ${saved.validationId}")
            }
            .doOnError { error ->
                logger.error("❌ Error guardando validación: ${error.message}", error)
            }
    }

    override fun findById(validationId: Long): Mono<ProductIdentificationValidation> {
        logger.debug("Buscando validación por ID: $validationId")

        return validationDAORepository.findById(validationId)
            .map { it.toDomain() }
            .doOnNext { logger.debug("Validación encontrada: ID ${it.validationId}") }
    }

    override fun findAll(): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando todas las validaciones")

        return validationDAORepository.findAll()
            .map { it.toDomain() }
    }

    override fun findByImageHash(imageHash: String): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando validaciones por imageHash: ${imageHash.take(16)}...")

        return validationDAORepository.findByImageHash(imageHash)
            .map { it.toDomain() }
            .doOnComplete { logger.debug("Búsqueda por imageHash completada") }
    }

    override fun findBySuggestedProductId(suggestedProductId: Long): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando validaciones por suggestedProductId: $suggestedProductId")

        return validationDAORepository.findBySuggestedProductId(suggestedProductId)
            .map { it.toDomain() }
    }

    override fun findByMatchType(matchType: String): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando validaciones por matchType: $matchType")

        return validationDAORepository.findByMatchType(matchType)
            .map { it.toDomain() }
    }

    override fun findByValidationSource(validationSource: String): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando validaciones por validationSource: $validationSource")

        return validationDAORepository.findByValidationSource(validationSource)
            .map { it.toDomain() }
    }

    override fun findByValidatedAtBetween(
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando validaciones entre $startDate y $endDate")

        return validationDAORepository.findByValidatedAtBetween(startDate, endDate)
            .map { it.toDomain() }
    }

    override fun countValidationsSinceLastTraining(): Mono<Long> {
        logger.debug("Contando validaciones desde último entrenamiento")

        return validationDAORepository.countValidationsSinceLastTraining()
            .doOnNext { count ->
                logger.debug("Validaciones desde último entrenamiento: $count")
            }
    }

    override fun findRecentValidations(limit: Int): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando últimas $limit validaciones")

        return validationDAORepository.findRecentValidations(limit)
            .map { it.toDomain() }
    }

    override fun findRecentValidationsByMatchType(
        matchType: String,
        limit: Int
    ): Flux<ProductIdentificationValidation> {
        logger.debug("Buscando últimas $limit validaciones de tipo $matchType")

        return validationDAORepository.findRecentValidationsByMatchType(matchType, limit)
            .map { it.toDomain() }
    }

    override fun countFalsePositives(): Mono<Long> {
        logger.debug("Contando false positives")

        return validationDAORepository.countFalsePositives()
            .doOnNext { count ->
                logger.debug("False positives: $count")
            }
    }

    override fun countFalseNegatives(): Mono<Long> {
        logger.debug("Contando false negatives")

        return validationDAORepository.countFalseNegatives()
            .doOnNext { count ->
                logger.debug("False negatives: $count")
            }
    }

    override fun deleteById(validationId: Long): Mono<Void> {
        logger.debug("Eliminando validación ID: $validationId")

        return validationDAORepository.deleteById(validationId)
            .doOnSuccess {
                logger.info("✅ Validación $validationId eliminada")
            }
            .doOnError { error ->
                logger.error("❌ Error eliminando validación $validationId: ${error.message}", error)
            }
    }
}
