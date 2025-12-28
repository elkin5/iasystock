package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono

/**
 * Use case para validación y sanitización de inputs del usuario
 * Protege contra inyecciones y contenido malicioso
 */
@Service
class InputValidationUseCase(
    private val securityAuditLogger: SecurityAuditLogger
) {

    private val logger = LoggerFactory.getLogger(InputValidationUseCase::class.java)

    companion object {
        // Límites de tamaño
        const val MAX_MESSAGE_LENGTH = 2000
        const val MIN_MESSAGE_LENGTH = 1

        // Patrones sospechosos
        val SQL_INJECTION_PATTERNS = listOf(
            "(?i)\\b(union|select|insert|update|delete|drop|create|alter|exec|execute)\\s+",
            "(?i)--;",
            "(?i)/\\*.*\\*/",
            "(?i)xp_cmdshell",
            "(?i)<script[^>]*>.*?</script>",
            "(?i)javascript:",
            "(?i)onerror\\s*=",
            "(?i)onload\\s*="
        )

        // Caracteres peligrosos excesivos
        val EXCESSIVE_SPECIAL_CHARS = Regex("[;'\"\\\\]{3,}")
    }

    /**
     * Valida y sanitiza el mensaje del usuario
     */
    fun validateAndSanitize(message: String, userId: Long, sessionId: String?): Mono<InputValidationResult> {
        return Mono.fromCallable {
            logger.debug("Validando input para usuario: $userId")

            // 1. Validar longitud
            if (message.length < MIN_MESSAGE_LENGTH) {
                return@fromCallable InputValidationResult(
                    isValid = false,
                    sanitizedMessage = null,
                    violationType = ViolationType.EMPTY_MESSAGE,
                    reason = "El mensaje está vacío"
                )
            }

            if (message.length > MAX_MESSAGE_LENGTH) {
                logger.warn("Mensaje excede longitud máxima: ${message.length} caracteres (usuario: $userId)")
                securityAuditLogger.logSecurityEvent(
                    userId = userId,
                    sessionId = sessionId,
                    eventType = SecurityEventType.INPUT_VALIDATION_FAILED,
                    severity = SecuritySeverity.MEDIUM,
                    description = "Mensaje excede longitud máxima: ${message.length} caracteres",
                    additionalData = mapOf("messageLength" to message.length)
                )

                return@fromCallable InputValidationResult(
                    isValid = false,
                    sanitizedMessage = null,
                    violationType = ViolationType.MESSAGE_TOO_LONG,
                    reason = "El mensaje excede el límite de $MAX_MESSAGE_LENGTH caracteres"
                )
            }

            // 2. Detectar patrones de SQL injection
            val sqlInjectionDetected = SQL_INJECTION_PATTERNS.any { pattern ->
                Regex(pattern).containsMatchIn(message)
            }

            if (sqlInjectionDetected) {
                logger.warn("Posible intento de SQL injection detectado (usuario: $userId): ${message.take(100)}")
                securityAuditLogger.logSecurityEvent(
                    userId = userId,
                    sessionId = sessionId,
                    eventType = SecurityEventType.SQL_INJECTION_ATTEMPT,
                    severity = SecuritySeverity.HIGH,
                    description = "Patrón de SQL injection detectado en mensaje",
                    additionalData = mapOf("message" to message.take(200))
                )

                return@fromCallable InputValidationResult(
                    isValid = false,
                    sanitizedMessage = null,
                    violationType = ViolationType.SQL_INJECTION_ATTEMPT,
                    reason = "El mensaje contiene patrones sospechosos"
                )
            }

            // 3. Detectar exceso de caracteres especiales
            if (EXCESSIVE_SPECIAL_CHARS.containsMatchIn(message)) {
                logger.warn("Exceso de caracteres especiales detectado (usuario: $userId)")
                securityAuditLogger.logSecurityEvent(
                    userId = userId,
                    sessionId = sessionId,
                    eventType = SecurityEventType.SUSPICIOUS_PATTERN,
                    severity = SecuritySeverity.MEDIUM,
                    description = "Exceso de caracteres especiales en mensaje",
                    additionalData = mapOf("message" to message.take(200))
                )

                return@fromCallable InputValidationResult(
                    isValid = false,
                    sanitizedMessage = null,
                    violationType = ViolationType.EXCESSIVE_SPECIAL_CHARS,
                    reason = "El mensaje contiene demasiados caracteres especiales"
                )
            }

            // 4. Sanitizar mensaje (limpiar espacios, normalizar)
            val sanitized = sanitizeMessage(message)

            // 5. Validar contenido después de sanitización
            if (sanitized.isBlank()) {
                return@fromCallable InputValidationResult(
                    isValid = false,
                    sanitizedMessage = null,
                    violationType = ViolationType.EMPTY_AFTER_SANITIZATION,
                    reason = "El mensaje queda vacío después de sanitización"
                )
            }

            // Mensaje válido
            logger.debug("Input validado exitosamente para usuario: $userId")
            InputValidationResult(
                isValid = true,
                sanitizedMessage = sanitized,
                violationType = null,
                reason = null
            )
        }
    }

    /**
     * Sanitiza el mensaje eliminando caracteres peligrosos
     */
    private fun sanitizeMessage(message: String): String {
        return message
            .trim()
            .replace(Regex("\\s+"), " ") // Normalizar espacios múltiples
            .replace(Regex("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]"), "") // Eliminar caracteres de control
    }
}

/**
 * Resultado de validación de input
 */
data class InputValidationResult(
    val isValid: Boolean,
    val sanitizedMessage: String?,
    val violationType: ViolationType?,
    val reason: String?
)

/**
 * Tipos de violaciones de validación
 */
enum class ViolationType {
    EMPTY_MESSAGE,
    MESSAGE_TOO_LONG,
    SQL_INJECTION_ATTEMPT,
    XSS_ATTEMPT,
    EXCESSIVE_SPECIAL_CHARS,
    EMPTY_AFTER_SANITIZATION,
    SUSPICIOUS_PATTERN
}
