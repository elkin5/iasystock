package com.co.kinsoft.api.iasy_stock_api.domain.service

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.IdentificationThresholdConfig
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ProductIdentificationValidation
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ThresholdConfigRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ValidationRepository
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDateTime

/**
 * Servicio de Machine Learning para ajuste automático de umbrales
 * de identificación basándose en validaciones humanas
 *
 * Funciones principales:
 * - Calcular métricas de precisión por tipo de match
 * - Ajustar umbrales automáticamente para mantener 90%+ de precisión
 * - Trigger automático de reentrenamiento cada N validaciones
 * - Versioning de configuraciones
 */
@Service
class ProductMLService(
    private val validationRepository: ValidationRepository,
    private val thresholdConfigRepository: ThresholdConfigRepository
) {

    private val logger: Logger = LoggerFactory.getLogger(ProductMLService::class.java)

    companion object {
        private const val TARGET_ACCURACY = 0.90  // 90% de precisión objetivo
        private const val MIN_VALIDATIONS_FOR_TRAINING = 100
        private const val THRESHOLD_ADJUSTMENT_STEP = 0.02  // Ajuste de 2%
        private const val MAX_THRESHOLD = 0.99
        private const val MIN_THRESHOLD = 0.50
    }

    /**
     * Verifica si hay suficientes validaciones para reentrenar
     * y ejecuta el reentrenamiento si es necesario
     *
     * @return Mono<Void> que se completa cuando termina el check
     */
    fun checkAndRetrain(): Mono<Void> {
        logger.debug("Verificando si es necesario reentrenar...")

        return validationRepository.countValidationsSinceLastTraining()
            .flatMap { count ->
                if (count >= MIN_VALIDATIONS_FOR_TRAINING) {
                    logger.info("Se encontraron $count validaciones nuevas. Iniciando reentrenamiento...")
                    adjustThresholds()
                        .flatMap { newConfig ->
                            thresholdConfigRepository.save(newConfig)
                        }
                        .doOnSuccess { saved ->
                            logger.info("✅ Reentrenamiento completado. Nueva configuración v${saved.modelVersion} guardada")
                        }
                        .then()
                } else {
                    logger.debug("Solo $count validaciones desde último entrenamiento. Se requieren $MIN_VALIDATIONS_FOR_TRAINING")
                    Mono.empty()
                }
            }
    }

    /**
     * Ajusta umbrales basándose en validaciones recientes
     *
     * Algoritmo:
     * 1. Para cada tipo de match, calcular precisión
     * 2. Si precisión >= 95%: reducir umbral (más permisivo)
     * 3. Si precisión < 90%: aumentar umbral (más estricto)
     * 4. Si precisión entre 90-95%: mantener umbral
     *
     * @return Nueva configuración de umbrales
     */
    fun adjustThresholds(): Mono<IdentificationThresholdConfig> {
        logger.info("Iniciando ajuste de umbrales basado en validaciones...")

        return validationRepository.findRecentValidations(limit = 1000)
            .collectList()
            .flatMap { validations ->
                if (validations.isEmpty()) {
                    logger.warn("No hay validaciones para calcular métricas")
                    return@flatMap thresholdConfigRepository.getActiveConfig()
                }

                // Calcular métricas por tipo de match
                val metricsByType = calculateMetricsByMatchType(validations)

                // Obtener configuración actual
                thresholdConfigRepository.getActiveConfig()
                    .map { currentConfig ->
                        adjustThresholdsBasedOnMetrics(currentConfig, metricsByType)
                    }
            }
    }

    /**
     * Calcula métricas de precisión por tipo de match
     *
     * @param validations Lista de validaciones
     * @return Mapa de tipo de match a métricas
     */
    private fun calculateMetricsByMatchType(validations: List<ProductIdentificationValidation>): Map<String, MatchTypeMetrics> {
        val metricsByType = mutableMapOf<String, MutableList<ValidationMetric>>()

        validations.forEach { validation ->
            val matchType = validation.matchType
            val metrics = metricsByType.getOrPut(matchType) { mutableListOf() }

            metrics.add(
                ValidationMetric(
                    wasCorrect = validation.wasCorrect,
                    confidenceScore = validation.confidenceScore
                )
            )
        }

        return metricsByType.mapValues { (matchType, metrics) ->
            val total = metrics.size
            val correct = metrics.count { it.wasCorrect }
            val accuracy = if (total > 0) correct.toDouble() / total.toDouble() else 0.0

            val avgConfidence = if (metrics.isNotEmpty()) {
                metrics.map { it.confidenceScore.toDouble() }.average()
            } else {
                0.0
            }

            MatchTypeMetrics(
                matchType = matchType,
                totalValidations = total,
                correctValidations = correct,
                accuracy = accuracy,
                averageConfidence = avgConfidence
            )
        }
    }

    /**
     * Ajusta umbrales basándose en métricas calculadas
     *
     * @param currentConfig Configuración actual
     * @param metricsByType Métricas por tipo de match
     * @return Nueva configuración ajustada
     */
    private fun adjustThresholdsBasedOnMetrics(
        currentConfig: IdentificationThresholdConfig,
        metricsByType: Map<String, MatchTypeMetrics>
    ): IdentificationThresholdConfig {

        logger.info("Ajustando umbrales basándose en métricas:")

        // Ajustar cada tipo de match
        val brandModelThreshold = adjustThreshold(
            current = currentConfig.brandModelMinConfidence,
            metrics = metricsByType["BRAND_MODEL"],
            name = "brand_model"
        )

        val vectorSimilarityThreshold = adjustThreshold(
            current = currentConfig.vectorSimilarityMinConfidence,
            metrics = metricsByType["VECTOR_SIMILARITY"],
            name = "vector_similarity"
        )

        val tagCategoryThreshold = adjustThreshold(
            current = currentConfig.tagCategoryMinConfidence,
            metrics = metricsByType["TAG_CATEGORY"],
            name = "tag_category"
        )

        // Calcular accuracy global
        val totalValidations = metricsByType.values.sumOf { it.totalValidations }
        val totalCorrect = metricsByType.values.sumOf { it.correctValidations }
        val globalAccuracy = if (totalValidations > 0) {
            BigDecimal(totalCorrect.toDouble() / totalValidations.toDouble())
                .setScale(4, RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }

        logger.info("Accuracy global: ${globalAccuracy.multiply(BigDecimal("100"))}%")

        // Incrementar versión del modelo
        val newVersion = incrementVersion(currentConfig.modelVersion)

        return currentConfig.copy(
            brandModelMinConfidence = brandModelThreshold,
            vectorSimilarityMinConfidence = vectorSimilarityThreshold,
            tagCategoryMinConfidence = tagCategoryThreshold,
            totalIdentifications = totalValidations,
            correctIdentifications = totalCorrect,
            accuracy = globalAccuracy,
            lastTrainingAt = LocalDateTime.now(),
            trainingSamplesCount = metricsByType.values.sumOf { it.totalValidations },
            modelVersion = newVersion,
            isActive = false, // La nueva config se activará al guardar
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
    }

    /**
     * Ajusta un umbral individual basándose en sus métricas
     *
     * @param current Umbral actual
     * @param metrics Métricas del tipo de match
     * @param name Nombre del umbral (para logging)
     * @return Umbral ajustado
     */
    private fun adjustThreshold(
        current: BigDecimal,
        metrics: MatchTypeMetrics?,
        name: String
    ): BigDecimal {
        if (metrics == null || metrics.totalValidations < 10) {
            logger.debug("$name: Sin suficientes datos, manteniendo umbral en $current")
            return current
        }

        val accuracy = metrics.accuracy
        var newThreshold = current

        when {
            // Alta precisión >= 95%: Reducir umbral (más permisivo)
            accuracy >= 0.95 -> {
                newThreshold = current.subtract(BigDecimal(THRESHOLD_ADJUSTMENT_STEP.toString()))
                logger.info("$name: Alta precisión (${(accuracy * 100).toInt()}%), reduciendo umbral $current → $newThreshold")
            }

            // Baja precisión < 90%: Aumentar umbral (más estricto)
            accuracy < TARGET_ACCURACY -> {
                newThreshold = current.add(BigDecimal(THRESHOLD_ADJUSTMENT_STEP.toString()))
                logger.info("$name: Baja precisión (${(accuracy * 100).toInt()}%), aumentando umbral $current → $newThreshold")
            }

            // Precisión óptima 90-95%: Mantener
            else -> {
                logger.info("$name: Precisión óptima (${(accuracy * 100).toInt()}%), manteniendo umbral en $current")
            }
        }

        // Aplicar límites
        newThreshold = when {
            newThreshold > BigDecimal(MAX_THRESHOLD.toString()) -> {
                logger.warn("$name: Umbral excede máximo, limitando a $MAX_THRESHOLD")
                BigDecimal(MAX_THRESHOLD.toString())
            }
            newThreshold < BigDecimal(MIN_THRESHOLD.toString()) -> {
                logger.warn("$name: Umbral por debajo de mínimo, limitando a $MIN_THRESHOLD")
                BigDecimal(MIN_THRESHOLD.toString())
            }
            else -> newThreshold
        }

        return newThreshold.setScale(4, RoundingMode.HALF_UP)
    }

    /**
     * Incrementa la versión del modelo
     *
     * @param currentVersion Versión actual (ej: "1.0", "1.5")
     * @return Nueva versión (ej: "1.1", "1.6")
     */
    private fun incrementVersion(currentVersion: String): String {
        return try {
            val parts = currentVersion.split(".")
            val major = parts[0].toInt()
            val minor = parts.getOrNull(1)?.toInt() ?: 0

            val newMinor = minor + 1

            // Si minor llega a 10, incrementar major
            if (newMinor >= 10) {
                "${major + 1}.0"
            } else {
                "$major.$newMinor"
            }
        } catch (e: Exception) {
            logger.warn("Error incrementando versión '$currentVersion', usando '1.1'")
            "1.1"
        }
    }

    /**
     * Calcula métricas generales del sistema
     *
     * @return Métricas del sistema
     */
    fun calculateMetrics(): Mono<SystemMetrics> {
        // TODO: Implementar cuando repositorios estén listos
        /*
        return validationRepository.findAll()
            .collectList()
            .flatMap { validations ->
                thresholdConfigRepository.getActiveConfig()
                    .map { config ->
                        val total = validations.size
                        val correct = validations.count { it.wasCorrect }
                        val accuracy = if (total > 0) correct.toDouble() / total.toDouble() else 0.0

                        val byType = validations.groupBy { it.matchType }
                        val metricsByType = byType.mapValues { (_, typeValidations) ->
                            val typeTotal = typeValidations.size
                            val typeCorrect = typeValidations.count { it.wasCorrect }
                            val typeAccuracy = if (typeTotal > 0) typeCorrect.toDouble() / typeTotal.toDouble() else 0.0

                            MatchTypeMetrics(
                                matchType = it.key,
                                totalValidations = typeTotal,
                                correctValidations = typeCorrect,
                                accuracy = typeAccuracy,
                                averageConfidence = typeValidations.map { it.confidenceScore }.average()
                            )
                        }

                        SystemMetrics(
                            totalIdentifications = total,
                            correctIdentifications = correct,
                            accuracy = accuracy,
                            metricsByType = metricsByType,
                            currentConfig = config
                        )
                    }
            }
        */

        // Implementación temporal
        return Mono.just(
            SystemMetrics(
                totalIdentifications = 0,
                correctIdentifications = 0,
                accuracy = 0.0,
                metricsByType = emptyMap(),
                currentConfig = IdentificationThresholdConfig()
            )
        )
    }
}

// ============================================================================
// DTOs para métricas
// ============================================================================

/**
 * Métricas por tipo de match
 */
data class MatchTypeMetrics(
    val matchType: String,
    val totalValidations: Int,
    val correctValidations: Int,
    val accuracy: Double,
    val averageConfidence: Double
)

/**
 * Métricas del sistema
 */
data class SystemMetrics(
    val totalIdentifications: Int,
    val correctIdentifications: Int,
    val accuracy: Double,
    val metricsByType: Map<String, MatchTypeMetrics>,
    val currentConfig: IdentificationThresholdConfig
)

/**
 * Métrica de una validación individual
 */
private data class ValidationMetric(
    val wasCorrect: Boolean,
    val confidenceScore: BigDecimal
)
