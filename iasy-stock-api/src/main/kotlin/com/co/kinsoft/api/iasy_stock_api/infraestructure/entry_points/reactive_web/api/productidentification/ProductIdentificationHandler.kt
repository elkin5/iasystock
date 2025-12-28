package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.*
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.ValidationUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.product.ProductUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.util.Base64

/**
 * Handler para endpoints de identificación inteligente de productos
 *
 * Endpoints:
 * - POST /api/v1/product-identification/identify-or-create
 * - POST /api/v1/product-identification/validate
 * - GET /api/v1/product-identification/validations/recent
 * - GET /api/v1/product-identification/config/active
 * - GET /api/v1/product-identification/metrics
 */
@Component
class ProductIdentificationHandler(
    private val productUseCase: ProductUseCase,
    private val validationUseCase: ValidationUseCase
) {

    private val logger: Logger = LoggerFactory.getLogger(ProductIdentificationHandler::class.java)

    /**
     * POST /api/v1/product-identification/identify-or-create
     *
     * Identifica o crea un producto a partir de una imagen
     */
    fun identifyOrCreate(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== POST /api/v1/product-identification/identify-or-create ===")

        return request.bodyToMono(IdentifyOrCreateProductRequestDTO::class.java)
            .flatMap { requestDTO ->
                // Decodificar imagen de base64
                val imageBytes = try {
                    Base64.getDecoder().decode(requestDTO.imageBase64)
                } catch (e: IllegalArgumentException) {
                    return@flatMap Mono.error<ServerResponse>(
                        IllegalArgumentException("Invalid base64 image data: ${e.message}")
                    )
                }

                // Validar tamaño de imagen (max 10MB)
                if (imageBytes.size > 10 * 1024 * 1024) {
                    return@flatMap Mono.error<ServerResponse>(
                        IllegalArgumentException("Image size exceeds 10MB limit")
                    )
                }

                logger.info("Procesando imagen: ${imageBytes.size} bytes, formato: ${requestDTO.imageFormat}")

                // Convertir DTO a dominio y procesar
                val domainRequest = requestDTO.toDomain(imageBytes)

                productUseCase.identifyOrCreateProduct(domainRequest)
                    .flatMap { result ->
                        val responseDTO = result.toDTO()

                        logger.info(
                            "✅ Procesamiento completado: status=${responseDTO.status}, " +
                            "producto=${responseDTO.product.name}, " +
                            "confianza=${responseDTO.confidence}, " +
                            "tiempo=${responseDTO.processingTimeMs}ms"
                        )

                        val httpStatus = when (result.status) {
                            IdentificationStatus.IDENTIFIED -> HttpStatus.OK
                            IdentificationStatus.PARTIAL_MATCH -> HttpStatus.OK
                            IdentificationStatus.NEW_PRODUCT_CREATED -> HttpStatus.CREATED
                            IdentificationStatus.MULTIPLE_MATCHES -> HttpStatus.OK
                            IdentificationStatus.ERROR -> HttpStatus.INTERNAL_SERVER_ERROR
                        }

                        ServerResponse
                            .status(httpStatus)
                            .contentType(MediaType.APPLICATION_JSON)
                            .bodyValue(ApiResponseDTO(
                                success = result.status != IdentificationStatus.ERROR,
                                data = responseDTO,
                                message = when (result.status) {
                                    IdentificationStatus.IDENTIFIED -> "Producto identificado exitosamente"
                                    IdentificationStatus.PARTIAL_MATCH -> "Match parcial encontrado, requiere validación"
                                    IdentificationStatus.NEW_PRODUCT_CREATED -> "Nuevo producto creado exitosamente"
                                    IdentificationStatus.MULTIPLE_MATCHES -> "Múltiples coincidencias encontradas"
                                    IdentificationStatus.ERROR -> "Error en identificación"
                                }
                            ))
                    }
            }
            .onErrorResume { error ->
                logger.error("❌ Error en identificación o creación: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error desconocido en procesamiento"
                    ))
            }
    }

    /**
     * POST /api/v1/product-identification/validate
     *
     * Registra una validación humana de una identificación
     */
    fun validateIdentification(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== POST /api/v1/product-identification/validate ===")

        return request.bodyToMono(ValidateIdentificationRequestDTO::class.java)
            .flatMap { requestDTO ->
                val domainRequest = requestDTO.toDomain()

                // Determinar tipo de corrección basado en wasCorrect
                val validation = if (requestDTO.wasCorrect) {
                    // Identificación correcta
                    validationUseCase.recordCorrectIdentification(
                        imageHash = domainRequest.imageHash,
                        imageUrl = null,
                        productId = domainRequest.actualProductId!!,
                        confidenceScore = domainRequest.confidenceScore,
                        matchType = domainRequest.matchType,
                        similarityScore = null,
                        userId = domainRequest.userId,
                        source = domainRequest.source,
                        relatedSaleId = domainRequest.relatedSaleId,
                        relatedStockId = domainRequest.relatedStockId,
                        notes = domainRequest.notes
                    )
                } else if (requestDTO.suggestedProductId != null && requestDTO.actualProductId == null) {
                    // False positive - se sugirió producto pero era nuevo
                    validationUseCase.recordFalsePositive(
                        imageHash = domainRequest.imageHash,
                        imageUrl = null,
                        suggestedProductId = requestDTO.suggestedProductId,
                        actualProductId = null,
                        confidenceScore = domainRequest.confidenceScore,
                        matchType = domainRequest.matchType,
                        userId = domainRequest.userId,
                        source = domainRequest.source,
                        relatedSaleId = domainRequest.relatedSaleId,
                        relatedStockId = domainRequest.relatedStockId,
                        notes = domainRequest.notes
                    )
                } else if (requestDTO.suggestedProductId == null && requestDTO.actualProductId != null) {
                    // False negative - no se identificó pero existía
                    validationUseCase.recordFalseNegative(
                        imageHash = domainRequest.imageHash,
                        imageUrl = null,
                        actualProductId = requestDTO.actualProductId,
                        userId = domainRequest.userId,
                        source = domainRequest.source,
                        relatedSaleId = domainRequest.relatedSaleId,
                        relatedStockId = domainRequest.relatedStockId,
                        notes = domainRequest.notes
                    )
                } else {
                    // Mejorado - se sugirió algo pero se corrigió
                    validationUseCase.recordImprovedIdentification(
                        imageHash = domainRequest.imageHash,
                        imageUrl = null,
                        suggestedProductId = requestDTO.suggestedProductId,
                        actualProductId = requestDTO.actualProductId!!,
                        confidenceScore = domainRequest.confidenceScore,
                        matchType = domainRequest.matchType,
                        userId = domainRequest.userId,
                        source = domainRequest.source,
                        relatedSaleId = domainRequest.relatedSaleId,
                        relatedStockId = domainRequest.relatedStockId,
                        notes = domainRequest.notes
                    )
                }

                validation.flatMap { savedValidation ->
                    val responseDTO = savedValidation.toDTO()

                    logger.info(
                        "✅ Validación guardada: ID=${responseDTO.validationId}, " +
                        "wasCorrect=${responseDTO.wasCorrect}, " +
                        "correctionType=${responseDTO.correctionType}"
                    )

                    ServerResponse
                        .status(HttpStatus.CREATED)
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(ApiResponseDTO(
                            success = true,
                            data = responseDTO,
                            message = "Validación registrada exitosamente"
                        ))
                }
            }
            .onErrorResume { error ->
                logger.error("❌ Error guardando validación: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error guardando validación"
                    ))
            }
    }

    /**
     * GET /api/v1/product-identification/validations/recent?limit=50
     *
     * Obtiene las validaciones más recientes
     */
    fun getRecentValidations(request: ServerRequest): Mono<ServerResponse> {
        val limit = request.queryParam("limit")
            .map { it.toIntOrNull() ?: 50 }
            .orElse(50)

        logger.info("=== GET /api/v1/product-identification/validations/recent?limit=$limit ===")

        return validationUseCase.getRecentValidations(limit)
            .map { it.toDTO() }
            .collectList()
            .flatMap { validations ->
                logger.info("✅ Retornando ${validations.size} validaciones recientes")

                ServerResponse
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO(
                        success = true,
                        data = validations,
                        message = "${validations.size} validaciones encontradas"
                    ))
            }
            .onErrorResume { error ->
                logger.error("❌ Error obteniendo validaciones: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error obteniendo validaciones"
                    ))
            }
    }

    /**
     * GET /api/v1/product-identification/config/active
     *
     * Obtiene la configuración activa de umbrales
     */
    fun getActiveConfig(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== GET /api/v1/product-identification/config/active ===")

        return validationUseCase.getActiveThresholdConfig()
            .flatMap { config ->
                val configDTO = config.toDTO()

                logger.info("✅ Configuración activa: versión ${configDTO.modelVersion}, accuracy ${configDTO.accuracy}")

                ServerResponse
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO(
                        success = true,
                        data = configDTO,
                        message = "Configuración activa obtenida exitosamente"
                    ))
            }
            .onErrorResume { error ->
                logger.error("❌ Error obteniendo configuración: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error obteniendo configuración"
                    ))
            }
    }

    /**
     * GET /api/v1/product-identification/metrics
     *
     * Obtiene métricas de precisión del sistema
     */
    fun getMetrics(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== GET /api/v1/product-identification/metrics ===")

        return validationUseCase.getAccuracyMetrics()
            .flatMap { metrics ->
                val accuracyPercentage = metrics.accuracy.multiply(java.math.BigDecimal("100")).setScale(2)

                val metricsDTO = AccuracyMetricsDTO(
                    totalValidations = metrics.totalValidations,
                    correctValidations = metrics.correctValidations,
                    falsePositives = metrics.falsePositives,
                    falseNegatives = metrics.falseNegatives,
                    accuracy = metrics.accuracy,
                    accuracyPercentage = "$accuracyPercentage%"
                )

                logger.info(
                    "✅ Métricas calculadas: total=${metricsDTO.totalValidations}, " +
                    "accuracy=${metricsDTO.accuracyPercentage}"
                )

                ServerResponse
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO(
                        success = true,
                        data = metricsDTO,
                        message = "Métricas obtenidas exitosamente"
                    ))
            }
            .onErrorResume { error ->
                logger.error("❌ Error calculando métricas: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error calculando métricas"
                    ))
            }
    }

    /**
     * POST /api/v1/product-identification/retrain
     *
     * Trigger manual de reentrenamiento del modelo ML
     */
    fun triggerRetraining(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== POST /api/v1/product-identification/retrain ===")

        return validationUseCase.triggerRetraining()
            .then(
                ServerResponse
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = true,
                        message = "Reentrenamiento completado exitosamente"
                    ))
            )
            .onErrorResume { error ->
                logger.error("❌ Error en reentrenamiento: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error en reentrenamiento"
                    ))
            }
    }

    /**
     * POST /api/v1/product-identification/identify-multiple
     *
     * Detecta e identifica múltiples productos en una sola imagen usando GPT-4 Vision
     */
    fun identifyMultiple(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== POST /api/v1/product-identification/identify-multiple ===")

        return request.bodyToMono(MultipleProductDetectionRequestDTO::class.java)
            .flatMap { requestDTO ->
                // Convertir DTO a modelo de dominio
                val domainRequest = requestDTO.toDomain()

                logger.info(
                    "Request: source=${domainRequest.source}, " +
                    "groupByProduct=${domainRequest.groupByProduct}, " +
                    "minConfidence=${domainRequest.minConfidence}"
                )

                // Ejecutar detección múltiple
                productUseCase.identifyMultipleProducts(domainRequest)
                    .flatMap { result ->
                        // Convertir resultado a DTO
                        val responseDTO = result.toDTO()

                        val httpStatus = when {
                            responseDTO.totalDetections == 0 -> HttpStatus.OK
                            responseDTO.uniqueProducts > 0 -> HttpStatus.OK
                            else -> HttpStatus.INTERNAL_SERVER_ERROR
                        }

                        val message = when {
                            responseDTO.totalDetections == 0 -> "No se detectaron objetos en la imagen"
                            responseDTO.uniqueProducts > 0 -> "Se detectaron ${responseDTO.uniqueProducts} productos (${responseDTO.totalDetections} objetos)"
                            else -> "Error en detección"
                        }

                        logger.info(
                            "✅ Detección completada: ${responseDTO.uniqueProducts} productos, " +
                            "${responseDTO.totalDetections} detecciones, " +
                            "${responseDTO.processingTimeMs}ms"
                        )

                        ServerResponse
                            .status(httpStatus)
                            .contentType(MediaType.APPLICATION_JSON)
                            .bodyValue(ApiResponseDTO(
                                success = responseDTO.uniqueProducts > 0 || responseDTO.totalDetections == 0,
                                data = responseDTO,
                                message = message
                            ))
                    }
            }
            .onErrorResume { error ->
                logger.error("❌ Error en detección múltiple: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error en detección múltiple"
                    ))
            }
    }
}
