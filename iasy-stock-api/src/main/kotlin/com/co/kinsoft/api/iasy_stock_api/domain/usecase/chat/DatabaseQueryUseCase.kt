package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatRepository
import org.slf4j.LoggerFactory
import reactor.core.publisher.Mono

class DatabaseQueryUseCase(
    private val sqlValidationUseCase: SQLValidationUseCase,
    private val chatRepository: ChatRepository
) {

    private val logger = LoggerFactory.getLogger(DatabaseQueryUseCase::class.java)

    /**
     * Ejecuta un query SQL con validación previa
     */
    fun executeQuery(query: String?, userId: Long = -1, sessionId: String? = null): Mono<String> {
        if (query.isNullOrBlank()) {
            return Mono.just("No se especificó una consulta válida")
        }

        logger.info("Ejecutando consulta con validación: ${query.take(100)}...")

        // 1. Validar SQL antes de ejecutar
        return sqlValidationUseCase.validateSQL(query, userId, sessionId)
            .flatMap { validation ->
                if (!validation.isValid) {
                    // Si la validación falla, retornar el error
                    logger.warn("Query no válido: ${validation.errorMessage}")
                    return@flatMap Mono.just(
                        "ERROR SQL: ${validation.errorMessage}\nSugerencia: ${validation.suggestion}"
                    )
                }

                // 2. Si es válido, ejecutar el query
                chatRepository.executeValidatedQuery(query)
            }
            .onErrorResume { error ->
                logger.error("Error ejecutando consulta: $query", error)
                Mono.just("Error ejecutando la consulta: ${error.message}")
            }
    }

    /**
     * Ejecuta query con validación y retorna resultado estructurado
     * Útil para el flujo de retry con auto-corrección
     */
    fun executeQueryWithValidation(query: String?, userId: Long = -1, sessionId: String? = null): Mono<QueryExecutionResult> {
        if (query.isNullOrBlank()) {
            return Mono.just(
                QueryExecutionResult(
                    success = false,
                    data = null,
                    error = "No se especificó una consulta válida",
                    validationResult = null
                )
            )
        }

        logger.info("Ejecutando consulta con validación completa: ${query.take(100)}...")

        return sqlValidationUseCase.validateSQL(query, userId, sessionId)
            .flatMap { validation ->
                if (!validation.isValid) {
                    // Retornar resultado con error de validación
                    Mono.just(
                        QueryExecutionResult(
                            success = false,
                            data = null,
                            error = validation.errorMessage,
                            validationResult = validation
                        )
                    )
                } else {
                    // Ejecutar y retornar resultado
                    chatRepository.executeValidatedQuery(query)
                        .map { data ->
                            QueryExecutionResult(
                                success = true,
                                data = data,
                                error = null,
                                validationResult = validation
                            )
                        }
                        .onErrorResume { error ->
                            Mono.just(
                                QueryExecutionResult(
                                    success = false,
                                    data = null,
                                    error = error.message ?: "Error desconocido",
                                    validationResult = validation
                                )
                            )
                        }
                }
            }
    }
}

/**
 * Resultado de ejecución de query con información de validación
 */
data class QueryExecutionResult(
    val success: Boolean,
    val data: String?,
    val error: String?,
    val validationResult: ValidationResult?
) 