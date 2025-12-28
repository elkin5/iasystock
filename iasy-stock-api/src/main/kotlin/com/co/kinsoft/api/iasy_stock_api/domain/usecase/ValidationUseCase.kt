package com.co.kinsoft.api.iasy_stock_api.domain.usecase

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.CorrectionType
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ProductIdentificationValidation
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ValidationSource
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ThresholdConfigRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ValidationRepository
import com.co.kinsoft.api.iasy_stock_api.domain.service.ProductMLService
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDateTime

/**
 * Caso de uso para validaciones de identificación de productos
 *
 * Responsabilidades:
 * - Guardar validaciones humanas de identificaciones
 * - Consultar métricas de validación
 * - Triggear reentrenamiento automático cuando hay suficientes validaciones
 * - Gestionar feedback loop de mejora continua
 */
class ValidationUseCase(
    private val validationRepository: ValidationRepository,
    private val thresholdConfigRepository: ThresholdConfigRepository,
    private val productMLService: ProductMLService
) {

    private val logger: Logger = LoggerFactory.getLogger(ValidationUseCase::class.java)

    /**
     * Guarda una validación de identificación
     *
     * @param validation Validación a guardar
     * @return Validación guardada
     */
    fun saveValidation(validation: ProductIdentificationValidation): Mono<ProductIdentificationValidation> {
        logger.info(
            "Guardando validación: imageHash=${validation.imageHash.take(16)}..., " +
            "wasCorrect=${validation.wasCorrect}, correctionType=${validation.correctionType}"
        )

        return validationRepository.save(validation)
            .flatMap { saved ->
                // Después de guardar, verificar si es necesario reentrenar
                productMLService.checkAndRetrain()
                    .then(Mono.just(saved))
            }
            .doOnSuccess { saved ->
                logger.info("✅ Validación guardada exitosamente: ID ${saved.validationId}")
            }
            .doOnError { error ->
                logger.error("❌ Error guardando validación: ${error.message}", error)
            }
    }

    /**
     * Crea y guarda una validación correcta (identificación fue exitosa)
     */
    fun recordCorrectIdentification(
        imageHash: String,
        imageUrl: String?,
        productId: Long,
        confidenceScore: BigDecimal,
        matchType: String,
        similarityScore: BigDecimal?,
        userId: Long,
        source: ValidationSource,
        relatedSaleId: Long? = null,
        relatedStockId: Long? = null,
        notes: String? = null
    ): Mono<ProductIdentificationValidation> {

        val validation = ProductIdentificationValidation(
            imageHash = imageHash,
            imageUrl = imageUrl,
            suggestedProductId = productId,
            actualProductId = productId,
            confidenceScore = confidenceScore,
            matchType = matchType,
            similarityScore = similarityScore,
            wasCorrect = true,
            correctionType = CorrectionType.CORRECT,
            validatedBy = userId,
            validatedAt = LocalDateTime.now(),
            feedbackNotes = notes,
            validationSource = source,
            relatedSaleId = relatedSaleId,
            relatedStockId = relatedStockId
        )

        return saveValidation(validation)
    }

    /**
     * Crea y guarda una validación de false positive
     * (se identificó como producto existente pero era nuevo)
     */
    fun recordFalsePositive(
        imageHash: String,
        imageUrl: String?,
        suggestedProductId: Long,
        actualProductId: Long?,
        confidenceScore: BigDecimal,
        matchType: String,
        userId: Long,
        source: ValidationSource,
        relatedSaleId: Long? = null,
        relatedStockId: Long? = null,
        notes: String? = null
    ): Mono<ProductIdentificationValidation> {

        val validation = ProductIdentificationValidation(
            imageHash = imageHash,
            imageUrl = imageUrl,
            suggestedProductId = suggestedProductId,
            actualProductId = actualProductId,
            confidenceScore = confidenceScore,
            matchType = matchType,
            wasCorrect = false,
            correctionType = CorrectionType.FALSE_POSITIVE,
            validatedBy = userId,
            validatedAt = LocalDateTime.now(),
            feedbackNotes = notes,
            validationSource = source,
            relatedSaleId = relatedSaleId,
            relatedStockId = relatedStockId
        )

        return saveValidation(validation)
    }

    /**
     * Crea y guarda una validación de false negative
     * (no se identificó pero el producto existía en la base de datos)
     */
    fun recordFalseNegative(
        imageHash: String,
        imageUrl: String?,
        actualProductId: Long,
        userId: Long,
        source: ValidationSource,
        relatedSaleId: Long? = null,
        relatedStockId: Long? = null,
        notes: String? = null
    ): Mono<ProductIdentificationValidation> {

        val validation = ProductIdentificationValidation(
            imageHash = imageHash,
            imageUrl = imageUrl,
            suggestedProductId = null,
            actualProductId = actualProductId,
            confidenceScore = BigDecimal.ZERO,
            matchType = "NONE",
            wasCorrect = false,
            correctionType = CorrectionType.FALSE_NEGATIVE,
            validatedBy = userId,
            validatedAt = LocalDateTime.now(),
            feedbackNotes = notes,
            validationSource = source,
            relatedSaleId = relatedSaleId,
            relatedStockId = relatedStockId
        )

        return saveValidation(validation)
    }

    /**
     * Crea y guarda una validación mejorada
     * (la identificación fue parcialmente correcta pero se mejoró)
     */
    fun recordImprovedIdentification(
        imageHash: String,
        imageUrl: String?,
        suggestedProductId: Long?,
        actualProductId: Long,
        confidenceScore: BigDecimal,
        matchType: String,
        userId: Long,
        source: ValidationSource,
        relatedSaleId: Long? = null,
        relatedStockId: Long? = null,
        notes: String? = null
    ): Mono<ProductIdentificationValidation> {

        val validation = ProductIdentificationValidation(
            imageHash = imageHash,
            imageUrl = imageUrl,
            suggestedProductId = suggestedProductId,
            actualProductId = actualProductId,
            confidenceScore = confidenceScore,
            matchType = matchType,
            wasCorrect = false,
            correctionType = CorrectionType.IMPROVED,
            validatedBy = userId,
            validatedAt = LocalDateTime.now(),
            feedbackNotes = notes,
            validationSource = source,
            relatedSaleId = relatedSaleId,
            relatedStockId = relatedStockId
        )

        return saveValidation(validation)
    }

    /**
     * Obtiene validaciones recientes
     */
    fun getRecentValidations(limit: Int = 50): Flux<ProductIdentificationValidation> {
        logger.debug("Obteniendo últimas $limit validaciones")
        return validationRepository.findRecentValidations(limit)
    }

    /**
     * Obtiene validaciones por tipo de match
     */
    fun getValidationsByMatchType(matchType: String, limit: Int = 50): Flux<ProductIdentificationValidation> {
        logger.debug("Obteniendo validaciones de tipo $matchType")
        return validationRepository.findRecentValidationsByMatchType(matchType, limit)
    }

    /**
     * Obtiene validaciones por fuente
     */
    fun getValidationsBySource(source: ValidationSource): Flux<ProductIdentificationValidation> {
        logger.debug("Obteniendo validaciones de fuente $source")
        return validationRepository.findByValidationSource(source.name)
    }

    /**
     * Obtiene validaciones en un rango de fechas
     */
    fun getValidationsByDateRange(
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): Flux<ProductIdentificationValidation> {
        logger.debug("Obteniendo validaciones entre $startDate y $endDate")
        return validationRepository.findByValidatedAtBetween(startDate, endDate)
    }

    /**
     * Cuenta validaciones desde el último entrenamiento
     */
    fun countValidationsSinceLastTraining(): Mono<Long> {
        return validationRepository.countValidationsSinceLastTraining()
    }

    /**
     * Obtiene métricas de precisión
     */
    fun getAccuracyMetrics(): Mono<AccuracyMetrics> {
        logger.debug("Calculando métricas de precisión")

        return Mono.zip(
            validationRepository.findAll().collectList(),
            validationRepository.countFalsePositives(),
            validationRepository.countFalseNegatives()
        ).map { tuple ->
            val allValidations = tuple.t1
            val falsePositives = tuple.t2
            val falseNegatives = tuple.t3

            val total = allValidations.size
            val correct = allValidations.count { it.wasCorrect }
            val accuracy = if (total > 0) correct.toDouble() / total.toDouble() else 0.0

            AccuracyMetrics(
                totalValidations = total,
                correctValidations = correct,
                falsePositives = falsePositives.toInt(),
                falseNegatives = falseNegatives.toInt(),
                accuracy = BigDecimal(accuracy)
            )
        }.doOnNext { metrics ->
            logger.info(
                "Métricas de precisión: total=${metrics.totalValidations}, " +
                "correctas=${metrics.correctValidations}, " +
                "accuracy=${metrics.accuracy.multiply(BigDecimal("100"))}%"
            )
        }
    }

    /**
     * Triggerea manualmente el reentrenamiento del modelo
     */
    fun triggerRetraining(): Mono<Void> {
        logger.info("Triggereando reentrenamiento manual del modelo ML")

        return productMLService.adjustThresholds()
            .flatMap { newConfig ->
                thresholdConfigRepository.save(newConfig)
            }
            .flatMap { saved ->
                thresholdConfigRepository.activateConfig(saved.configId!!)
            }
            .then()
            .doOnSuccess {
                logger.info("✅ Reentrenamiento manual completado exitosamente")
            }
            .doOnError { error ->
                logger.error("❌ Error en reentrenamiento manual: ${error.message}", error)
            }
    }

    /**
     * Obtiene la configuración activa de umbrales
     */
    fun getActiveThresholdConfig() = thresholdConfigRepository.getActiveConfig()

    /**
     * Obtiene todas las configuraciones ordenadas por accuracy
     */
    fun getAllConfigsOrderedByAccuracy() = thresholdConfigRepository.findAllOrderedByAccuracy()
}

/**
 * DTO para métricas de precisión
 */
data class AccuracyMetrics(
    val totalValidations: Int,
    val correctValidations: Int,
    val falsePositives: Int,
    val falseNegatives: Int,
    val accuracy: BigDecimal
)
