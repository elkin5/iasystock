package com.co.kinsoft.api.iasy_stock_api.domain.service

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.*
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.VisionAnalysisResult
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.math.RoundingMode

/**
 * Servicio de identificación de productos - NUEVO FLUJO SIMPLIFICADO
 *
 * Estrategia de identificación:
 * 1. PASO 1: Análisis Vision (externo - viene de OpenAIService)
 * 2. PASO 2: Búsqueda por campos exactos (brand_name, model_number, inferred_category)
 *    - Si encuentra 1 resultado → calcular similitud y retornar
 *    - Si encuentra N resultados → desempatar por tags
 *    - Si encuentra 0 resultados → ir a Paso 3
 * 3. PASO 3: Búsqueda por embedding (solo si Paso 2 no encontró nada)
 *    - Retorna SOLO UN resultado (el más similar)
 *    - Sin desambiguación compleja
 *
 * Cálculo de similitud (Paso 2):
 * - Base: 60% (por coincidir brand + model + category)
 * - Bonus logos: hasta +20% (proporcional a coincidencias)
 * - Bonus objects: hasta +20% (proporcional a coincidencias)
 * - Total máximo: 100%
 */
@Service
class ProductIdentificationService(
    private val productRepository: ProductRepository,
    private val objectMapper: ObjectMapper
) {

    private val logger: Logger = LoggerFactory.getLogger(ProductIdentificationService::class.java)

    companion object {
        // Porcentajes de similitud
        private val BASE_SIMILARITY = BigDecimal("0.60")      // 60% base
        private val MAX_LOGOS_BONUS = BigDecimal("0.20")      // +20% máximo por logos
        private val MAX_OBJECTS_BONUS = BigDecimal("0.20")    // +20% máximo por objects
    }

    /**
     * Identifica un producto usando el NUEVO FLUJO:
     * Paso 2 → Campos exactos + similitud por logos/objects
     * Paso 3 → Embedding (solo si Paso 2 falla)
     *
     * @param visionResult Resultado del análisis de Vision (Paso 1 ya completado)
     * @return IdentificationMatch con el producto identificado o Mono.empty() si no se encuentra
     */
    fun identifyProduct(
        visionResult: VisionAnalysisResult
    ): Mono<IdentificationMatch> {

        logger.info("🔍 Iniciando identificación (NUEVO FLUJO)")
        logger.info("  Vision: brand=${visionResult.brandName}, model=${visionResult.modelNumber}, " +
                "category=${visionResult.inferredCategory}")
        logger.info("  Logos: ${visionResult.detectedLogos}, Objects: ${visionResult.detectedObjects}")

        // PASO 2: Búsqueda por campos exactos
        return searchByExactFields(visionResult)
            .switchIfEmpty(Mono.defer {
                // PASO 3: Si no se encontró nada, buscar por embedding
                logger.info("⚠️ Paso 2 no encontró coincidencias, pasando a Paso 3 (embedding)")
                Mono.empty()
            })
            .doOnNext { match ->
                logger.info("✅ Producto identificado: ${match.product.name} " +
                    "(tipo=${match.matchType}, similitud=${(match.confidence * BigDecimal("100")).toInt()}%)")
            }
    }

    /**
     * PASO 2: Búsqueda por campos exactos (brand_name, model_number, inferred_category)
     * Calcula similitud basada en logos y objects detectados
     */
    private fun searchByExactFields(
        visionResult: VisionAnalysisResult
    ): Mono<IdentificationMatch> {

        logger.info("📍 PASO 2: Buscando por campos exactos...")

        return productRepository.findByExactFields(
            brandName = visionResult.brandName,
            modelNumber = visionResult.modelNumber,
            inferredCategory = visionResult.inferredCategory
        )
            .collectList()
            .flatMap { candidates ->
                if (candidates.isEmpty()) {
                    logger.info("  ❌ No se encontraron candidatos por campos exactos")
                    return@flatMap Mono.empty<IdentificationMatch>()
                }

                logger.info("  📦 Encontrados ${candidates.size} candidato(s) por campos exactos")

                // Calcular similitud para cada candidato
                val scoredCandidates = candidates.map { product ->
                    calculateSimilarityScore(product, visionResult)
                }

                // Si hay UN solo candidato, retornarlo
                if (scoredCandidates.size == 1) {
                    val scored = scoredCandidates[0]
                    logger.info("  ✅ Único candidato: ${scored.product.name} (${formatPercent(scored.totalSimilarity)})")
                    return@flatMap Mono.just(scored.toIdentificationMatch())
                }

                // Si hay MÚLTIPLES candidatos, desempatar por tags
                logger.info("  🔧 Múltiples candidatos, desempatando por tags...")
                val bestCandidate = disambiguateByTags(scoredCandidates, visionResult)

                logger.info("  ✅ Mejor candidato: ${bestCandidate.product.name} (${formatPercent(bestCandidate.totalSimilarity)})")
                Mono.just(bestCandidate.toIdentificationMatch())
            }
    }

    /**
     * Calcula la similitud de un producto basado en logos y objects detectados
     *
     * Fórmula:
     * - Base: 60% (por coincidir brand + model + category)
     * - Logos: +20% × (coincidencias / max(logos_imagen, logos_bd))
     * - Objects: +20% × (coincidencias / max(objects_imagen, objects_bd))
     *
     * Casos especiales:
     * - Si ambos arrays están vacíos → se considera match completo (+20%)
     */
    private fun calculateSimilarityScore(
        product: Product,
        visionResult: VisionAnalysisResult
    ): ScoredCandidate {

        // Extraer logos del producto (JSON string → List)
        val productLogos = extractLogosFromJson(product.logoDetection)
        val imageLogos = visionResult.detectedLogos

        // Extraer objects del producto (JSON string → List)
        val productObjects = extractObjectsFromJson(product.objectDetection)
        val imageObjects = visionResult.detectedObjects

        // Calcular bonus de logos
        val logosBonus = calculateArrayBonus(imageLogos, productLogos, MAX_LOGOS_BONUS)

        // Calcular bonus de objects
        val objectsBonus = calculateArrayBonus(imageObjects, productObjects, MAX_OBJECTS_BONUS)

        // Similitud total
        val totalSimilarity = BASE_SIMILARITY.add(logosBonus).add(objectsBonus)

        logger.debug("    ${product.name}: base=60% + logos=${formatPercent(logosBonus)} + objects=${formatPercent(objectsBonus)} = ${formatPercent(totalSimilarity)}")

        return ScoredCandidate(
            product = product,
            baseSimilarity = BASE_SIMILARITY,
            logosBonus = logosBonus,
            objectsBonus = objectsBonus,
            totalSimilarity = totalSimilarity,
            matchingLogos = imageLogos.intersect(productLogos.toSet()).toList(),
            matchingObjects = imageObjects.intersect(productObjects.toSet()).toList()
        )
    }

    /**
     * Calcula el bonus proporcional para arrays de logos/objects
     *
     * @param imageArray Array de la imagen analizada
     * @param productArray Array del producto en BD
     * @param maxBonus Bonus máximo (0.20 = 20%)
     * @return Bonus proporcional
     */
    private fun calculateArrayBonus(
        imageArray: List<String>,
        productArray: List<String>,
        maxBonus: BigDecimal
    ): BigDecimal {
        // Caso especial: ambos vacíos = match completo
        if (imageArray.isEmpty() && productArray.isEmpty()) {
            return maxBonus
        }

        // Si solo uno está vacío, no hay coincidencias
        if (imageArray.isEmpty() || productArray.isEmpty()) {
            return BigDecimal.ZERO
        }

        // Contar coincidencias (case-insensitive)
        val imageLower = imageArray.map { it.lowercase() }
        val productLower = productArray.map { it.lowercase() }
        val matches = imageLower.intersect(productLower.toSet()).size

        // Calcular proporción basada en el máximo de ambos arrays
        val maxSize = maxOf(imageArray.size, productArray.size)
        val ratio = matches.toBigDecimal().divide(maxSize.toBigDecimal(), 4, RoundingMode.HALF_UP)

        return maxBonus.multiply(ratio).setScale(4, RoundingMode.HALF_UP)
    }

    /**
     * Desempata múltiples candidatos usando tags (inferred_usage_tags + image_tags)
     * Retorna el candidato con más tags coincidentes
     */
    private fun disambiguateByTags(
        candidates: List<ScoredCandidate>,
        visionResult: VisionAnalysisResult
    ): ScoredCandidate {

        val imageTags = (visionResult.inferredUsageTags + visionResult.imageTags)
            .map { it.lowercase() }
            .toSet()

        if (imageTags.isEmpty()) {
            // Sin tags para desempatar, retornar el de mayor similitud
            return candidates.maxByOrNull { it.totalSimilarity } ?: candidates.first()
        }

        return candidates.maxByOrNull { candidate ->
            val productTags = ((candidate.product.inferredUsageTags ?: emptyList()) +
                    (candidate.product.imageTags ?: emptyList()))
                .map { it.lowercase() }
                .toSet()

            val matchingTags = imageTags.intersect(productTags).size
            logger.debug("    ${candidate.product.name}: $matchingTags tags coincidentes")
            matchingTags
        } ?: candidates.first()
    }

    /**
     * PASO 3: Búsqueda por embedding (solo si Paso 2 no encontró nada)
     * Retorna SOLO UN resultado (el más similar), sin desambiguación
     */
    fun searchByEmbedding(
        imageEmbedding: String,
        config: IdentificationThresholdConfig
    ): Mono<IdentificationMatch> {

        logger.info("📍 PASO 3: Buscando por embedding...")

        return productRepository.findMostSimilarProduct(
            imageEmbedding = imageEmbedding,
            similarityThreshold = config.vectorSimilarityMinConfidence
        )
            .map { product ->
                // La similitud real está en recognitionAccuracy (calculada por pgVector)
                val similarity = product.recognitionAccuracy ?: BigDecimal.ZERO

                logger.info("  ✅ Encontrado por embedding: ${product.name} (similitud: ${formatPercent(similarity)})")

                IdentificationMatch(
                    product = product,
                    confidence = similarity,
                    matchType = MatchType.VECTOR_SIMILARITY,
                    details = "Match por similitud de embeddings (${formatPercent(similarity)})",
                    similarity = similarity,
                    metadata = mapOf(
                        "match_method" to "embedding",
                        "similarity" to similarity
                    )
                )
            }
            .doOnSubscribe {
                logger.debug("  Buscando producto más similar por embedding...")
            }
            .switchIfEmpty(Mono.defer {
                logger.info("  ❌ No se encontró producto similar por embedding")
                Mono.empty()
            })
    }

    // ==================== HELPERS ====================

    /**
     * Extrae detected_logos del JSON de logo_detection
     * Formato esperado: {"timestamp": "...", "confidence": 0.9, "detected_logos": ["Logo1", "Logo2"]}
     */
    private fun extractLogosFromJson(logoDetectionJson: String?): List<String> {
        if (logoDetectionJson.isNullOrBlank() || logoDetectionJson == "{}") {
            return emptyList()
        }
        return try {
            val node = objectMapper.readTree(logoDetectionJson)
            node.get("detected_logos")?.map { it.asText() } ?: emptyList()
        } catch (e: Exception) {
            logger.warn("Error parsing logo_detection JSON: ${e.message}")
            emptyList()
        }
    }

    /**
     * Extrae detected_objects del JSON de object_detection
     * Formato esperado: {"timestamp": "...", "confidence": 0.85, "detected_objects": ["Obj1", "Obj2"]}
     */
    private fun extractObjectsFromJson(objectDetectionJson: String?): List<String> {
        if (objectDetectionJson.isNullOrBlank() || objectDetectionJson == "{}") {
            return emptyList()
        }
        return try {
            val node = objectMapper.readTree(objectDetectionJson)
            node.get("detected_objects")?.map { it.asText() } ?: emptyList()
        } catch (e: Exception) {
            logger.warn("Error parsing object_detection JSON: ${e.message}")
            emptyList()
        }
    }

    private fun formatPercent(value: BigDecimal): String {
        return "${(value * BigDecimal("100")).setScale(1, RoundingMode.HALF_UP)}%"
    }

    // ==================== MODELOS INTERNOS ====================

    /**
     * Candidato con puntuación calculada
     */
    private data class ScoredCandidate(
        val product: Product,
        val baseSimilarity: BigDecimal,
        val logosBonus: BigDecimal,
        val objectsBonus: BigDecimal,
        val totalSimilarity: BigDecimal,
        val matchingLogos: List<String>,
        val matchingObjects: List<String>
    ) {
        fun toIdentificationMatch(): IdentificationMatch {
            return IdentificationMatch(
                product = product,
                confidence = totalSimilarity.min(BigDecimal.ONE), // Cap at 100%
                matchType = MatchType.VISION_MATCH,
                details = buildDetails(),
                similarity = totalSimilarity,
                metadata = mapOf(
                    "match_method" to "vision_fields",
                    "base_similarity" to baseSimilarity,
                    "logos_bonus" to logosBonus,
                    "objects_bonus" to objectsBonus,
                    "total_similarity" to totalSimilarity,
                    "matching_logos" to matchingLogos,
                    "matching_objects" to matchingObjects
                )
            )
        }

        private fun buildDetails(): String {
            val parts = mutableListOf("Base: 60%")
            if (logosBonus > BigDecimal.ZERO) {
                parts.add("logos: +${(logosBonus * BigDecimal("100")).setScale(1, RoundingMode.HALF_UP)}%")
            }
            if (objectsBonus > BigDecimal.ZERO) {
                parts.add("objects: +${(objectsBonus * BigDecimal("100")).setScale(1, RoundingMode.HALF_UP)}%")
            }
            return "Match por campos Vision (${parts.joinToString(", ")})"
        }
    }
}
