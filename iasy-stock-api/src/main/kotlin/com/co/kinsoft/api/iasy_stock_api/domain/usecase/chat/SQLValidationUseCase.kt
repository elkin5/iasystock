package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.SchemaWhitelistUseCase
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatRepository
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono

@Service
class SQLValidationUseCase(
    private val chatRepository: ChatRepository,
    private val schemaWhitelistUseCase: SchemaWhitelistUseCase,
    @Value("\${spring.profiles.active:prod}")
    private val activeProfile: String
) {

    private val logger = LoggerFactory.getLogger(SQLValidationUseCase::class.java)

    /**
     * Valida un query SQL antes de ejecutarlo
     * Retorna un ValidationResult con el estado y detalles del error si existe
     */
    fun validateSQL(query: String, userId: Long = -1, sessionId: String? = null): Mono<ValidationResult> {
        return Mono.fromCallable {
            logger.debug("Validando SQL: ${query.take(100)}...")

            // Validaciones básicas de sintaxis
            val basicValidation = performBasicValidation(query)
            if (!basicValidation.isValid) {
                return@fromCallable basicValidation
            }

            basicValidation
        }.flatMap { basicResult ->
            if (!basicResult.isValid) {
                return@flatMap Mono.just(basicResult)
            }

            // Validación de schema whitelist
            schemaWhitelistUseCase.validateSchemaAccess(query, userId, sessionId)
                .flatMap { schemaValidation ->
                    if (!schemaValidation.isValid) {
                        return@flatMap Mono.just(
                            ValidationResult(
                                isValid = false,
                                errorMessage = schemaValidation.reason,
                                errorType = ErrorType.SCHEMA_VIOLATION,
                                suggestion = "Verifica que solo uses tablas y columnas autorizadas del sistema"
                            )
                        )
                    }

                    // OPTIMIZACIÓN: Validación con EXPLAIN solo en desarrollo/staging
                    // En producción se omite para mejorar rendimiento (-200-500ms)
                    if (shouldPerformExplainValidation()) {
                        logger.debug("Ejecutando validación EXPLAIN (ambiente: $activeProfile)")
                        chatRepository.performExplainValidation(query)
                    } else {
                        logger.debug("Omitiendo validación EXPLAIN en producción")
                        Mono.just(
                            ValidationResult(
                                isValid = true,
                                errorMessage = null,
                                errorType = null,
                                suggestion = null
                            )
                        )
                    }
                }
        }.onErrorResume { error ->
            logger.warn("Error durante validación SQL: ${error.message}")
            Mono.just(
                ValidationResult(
                    isValid = false,
                    errorMessage = "Error de validación: ${error.message}",
                    errorType = ErrorType.VALIDATION_ERROR,
                    suggestion = "Verifica la sintaxis SQL y las tablas/columnas referenciadas"
                )
            )
        }
    }

    /**
     * Validaciones básicas de sintaxis SQL
     */
    private fun performBasicValidation(query: String): ValidationResult {
        val normalizedQuery = query.trim().uppercase()

        // 1. Verificar que no esté vacío
        if (normalizedQuery.isBlank()) {
            return ValidationResult(
                isValid = false,
                errorMessage = "El query SQL está vacío",
                errorType = ErrorType.EMPTY_QUERY,
                suggestion = "Proporciona un query SQL válido"
            )
        }

        // 2. Solo permitir SELECT (seguridad)
        if (!normalizedQuery.startsWith("SELECT")) {
            return ValidationResult(
                isValid = false,
                errorMessage = "Solo se permiten queries SELECT por seguridad",
                errorType = ErrorType.FORBIDDEN_OPERATION,
                suggestion = "Usa solo queries SELECT para consultar datos"
            )
        }

        // 3. Verificar palabras clave prohibidas (seguridad adicional)
        val forbiddenKeywords = listOf(
            "DROP", "DELETE", "INSERT", "UPDATE", "TRUNCATE",
            "ALTER", "CREATE", "GRANT", "REVOKE"
        )

        val queryWords = normalizedQuery.split("\\s+".toRegex())
        val foundForbidden = forbiddenKeywords.find { keyword ->
            queryWords.contains(keyword)
        }

        if (foundForbidden != null) {
            return ValidationResult(
                isValid = false,
                errorMessage = "Query contiene operación prohibida: $foundForbidden",
                errorType = ErrorType.FORBIDDEN_OPERATION,
                suggestion = "Solo se permiten consultas de lectura (SELECT)"
            )
        }

        // 4. Verificar que tenga FROM
        if (!normalizedQuery.contains("FROM")) {
            return ValidationResult(
                isValid = false,
                errorMessage = "Query SELECT debe incluir cláusula FROM",
                errorType = ErrorType.SYNTAX_ERROR,
                suggestion = "Agrega la cláusula FROM especificando la tabla a consultar"
            )
        }

        // 5. Verificar paréntesis balanceados
        val openParens = query.count { it == '(' }
        val closeParens = query.count { it == ')' }
        if (openParens != closeParens) {
            return ValidationResult(
                isValid = false,
                errorMessage = "Paréntesis desbalanceados (abiertos: $openParens, cerrados: $closeParens)",
                errorType = ErrorType.SYNTAX_ERROR,
                suggestion = "Verifica que todos los paréntesis estén correctamente cerrados"
            )
        }

        // 6. Verificar que use el schema correcto
        if (!normalizedQuery.contains("SCHMAIN.")) {
            logger.warn("Query no usa el schema 'schmain' explícitamente: ${query.take(100)}")
            // No rechazamos, solo advertimos
        }

        // Si pasó todas las validaciones básicas
        return ValidationResult(
            isValid = true,
            errorMessage = null,
            errorType = null,
            suggestion = null
        )
    }

    /**
     * Determina si se debe ejecutar validación EXPLAIN basándose en el perfil activo
     * Solo se ejecuta en desarrollo y staging para mejorar rendimiento en producción
     */
    private fun shouldPerformExplainValidation(): Boolean {
        return activeProfile.contains("dev", ignoreCase = true) ||
                activeProfile.contains("staging", ignoreCase = true) ||
                activeProfile.contains("test", ignoreCase = true)
    }
}

/**
 * Resultado de validación SQL
 */
data class ValidationResult(
    val isValid: Boolean,
    val errorMessage: String?,
    val errorType: ErrorType?,
    val suggestion: String?
)

/**
 * Tipos de errores SQL
 */
enum class ErrorType {
    EMPTY_QUERY,
    FORBIDDEN_OPERATION,
    SYNTAX_ERROR,
    TABLE_NOT_FOUND,
    COLUMN_NOT_FOUND,
    AGGREGATE_ERROR,
    GROUP_BY_ERROR,
    JOIN_ERROR,
    AMBIGUOUS_COLUMN,
    TYPE_MISMATCH,
    EXPLAIN_FAILED,
    VALIDATION_ERROR,
    SCHEMA_VIOLATION,
    UNKNOWN_ERROR
}
