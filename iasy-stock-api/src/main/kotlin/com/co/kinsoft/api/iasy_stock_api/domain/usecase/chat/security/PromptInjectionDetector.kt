package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono

/**
 * Detector de intentos de prompt injection
 * Identifica patrones que intentan manipular el comportamiento del asistente AI
 */
@Service
class PromptInjectionDetector(
    private val securityAuditLogger: SecurityAuditLogger
) {

    private val logger = LoggerFactory.getLogger(PromptInjectionDetector::class.java)

    companion object {
        // Patrones de prompt injection conocidos
        val INJECTION_PATTERNS = listOf(
            // Intentos de ignorar instrucciones
            "(?i)ignor(a|e|ar|ing)\\s+(todas?|las?|tus?|previous|anteriores?)\\s+(instrucciones?|reglas?|comandos?)",
            "(?i)olvid(a|e|ar|ate)\\s+(todo|las?\\s+instrucciones?)",
            "(?i)reset\\s+(system|instructions)",

            // Intentos de cambiar el rol
            "(?i)(eres?|you\\s+are|act\\s+as)\\s+(ahora|now)?\\s+(un|una|a)?\\s+(sistema|system|administrador|admin|root)",
            "(?i)actua\\s+como\\s+(si|un|una)",
            "(?i)pretend\\s+(to\\s+be|you\\s+are)",

            // Intentos de revelar el prompt del sistema
            "(?i)(muestra|show|reveal|devuelve|return)\\s+(el|tu|your|tus)?\\s+(prompt|instrucciones?|system\\s+prompt)",
            "(?i)cual\\s+es\\s+tu\\s+(prompt|configuracion|setup)",
            "(?i)print\\s+(system|prompt|instructions)",

            // Intentos de bypass de restricciones
            "(?i)(no\\s+hay|sin|without)\\s+(restricciones?|limites?|limits?|restrictions?)",
            "(?i)(desactiv|disable|deshabili)(a|e|ar|ate)\\s+(filtros?|filters?|restricciones?|validaciones?)",
            "(?i)modo\\s+(desarrollador|developer|debug|god|admin)",

            // Intentos de inyección de comandos
            "(?i)(ejecut|exec|run|corr)(a|e|ar|e)\\s+(comando|command|script|código|code)",
            "(?i)(accede|access|lee|read)\\s+(archivos?|files?|sistema|system)",

            // Intentos de manipulación con delimitadores
            "(?i)(###|---|===|\\*\\*\\*)\\s*(system|instrucciones?|prompt)",
            "(?i)\\[system\\]",
            "(?i)<\\|system\\|>",

            // Intentos de encodings/ofuscación
            "(?i)(base64|hex|encode|decode|rot13|caesar)",
            "(?i)(\\\\x|\\\\u|%[0-9a-f]{2}){3,}", // Secuencias de caracteres encoded

            // Intentos de jailbreak conocidos
            "(?i)DAN\\s+mode",
            "(?i)do\\s+anything\\s+now",
            "(?i)jailbreak",
            "(?i)evil\\s+mode",

            // Intentos de extraer información sensible
            "(?i)(api\\s+key|password|secret|token|credential|contraseña)",
            "(?i)dame\\s+(acceso|access|permisos|permissions)"
        )

        // Patrones de delimitadores sospechosos
        val SUSPICIOUS_DELIMITERS = listOf(
            Regex("(###){2,}"),
            Regex("(---){2,}"),
            Regex("(===){2,}"),
            Regex("(\\*\\*\\*){2,}"),
            Regex("\\[\\[.*\\]\\]"),
            Regex("<<.*>>"),
            Regex("<\\|.*\\|>")
        )

        // Palabras clave en contextos sospechosos
        val SUSPICIOUS_KEYWORDS = listOf(
            "system", "admin", "root", "sudo", "chmod",
            "bypass", "hack", "exploit", "vulnerability",
            "jailbreak", "unrestricted", "unlimited"
        )
    }

    /**
     * Analiza el mensaje en busca de patrones de prompt injection
     */
    fun detectPromptInjection(
        message: String,
        userId: Long,
        sessionId: String?
    ): Mono<PromptInjectionResult> {
        return Mono.fromCallable {
            logger.debug("Analizando posible prompt injection para usuario: $userId")

            // 1. Verificar patrones conocidos de inyección
            val injectionPattern = INJECTION_PATTERNS.firstOrNull { pattern ->
                Regex(pattern).containsMatchIn(message)
            }

            if (injectionPattern != null) {
                logger.warn("Patrón de prompt injection detectado (usuario: $userId): $injectionPattern")
                securityAuditLogger.logAttackAttempt(
                    userId = userId,
                    sessionId = sessionId,
                    attackType = "PROMPT_INJECTION",
                    details = "Patrón detectado: ${injectionPattern.take(100)}",
                    payload = message
                )

                return@fromCallable PromptInjectionResult(
                    isInjection = true,
                    confidence = ConfidenceLevel.HIGH,
                    detectedPattern = injectionPattern.take(50),
                    reason = "Patrón de prompt injection conocido detectado"
                )
            }

            // 2. Verificar delimitadores sospechosos
            val suspiciousDelimiter = SUSPICIOUS_DELIMITERS.firstOrNull { regex ->
                regex.containsMatchIn(message)
            }

            if (suspiciousDelimiter != null) {
                logger.warn("Delimitador sospechoso detectado (usuario: $userId)")
                securityAuditLogger.logSecurityEvent(
                    userId = userId,
                    sessionId = sessionId,
                    eventType = SecurityEventType.PROMPT_INJECTION_ATTEMPT,
                    severity = SecuritySeverity.MEDIUM,
                    description = "Delimitador sospechoso detectado",
                    additionalData = mapOf("message" to message.take(200))
                )

                return@fromCallable PromptInjectionResult(
                    isInjection = true,
                    confidence = ConfidenceLevel.MEDIUM,
                    detectedPattern = "Delimitador sospechoso",
                    reason = "Uso de delimitadores que podrían manipular el contexto del prompt"
                )
            }

            // 3. Análisis heurístico: contar keywords sospechosas
            val suspiciousKeywordCount = SUSPICIOUS_KEYWORDS.count { keyword ->
                message.contains(keyword, ignoreCase = true)
            }

            if (suspiciousKeywordCount >= 3) {
                logger.warn("Múltiples keywords sospechosas detectadas (usuario: $userId): $suspiciousKeywordCount")
                securityAuditLogger.logSecurityEvent(
                    userId = userId,
                    sessionId = sessionId,
                    eventType = SecurityEventType.SUSPICIOUS_PATTERN,
                    severity = SecuritySeverity.MEDIUM,
                    description = "Múltiples keywords sospechosas: $suspiciousKeywordCount",
                    additionalData = mapOf("message" to message.take(200))
                )

                return@fromCallable PromptInjectionResult(
                    isInjection = true,
                    confidence = ConfidenceLevel.MEDIUM,
                    detectedPattern = "Múltiples keywords sospechosas ($suspiciousKeywordCount)",
                    reason = "El mensaje contiene múltiples términos asociados con intentos de manipulación"
                )
            } else if (suspiciousKeywordCount >= 2) {
                // Nivel bajo de sospecha, pero registrar
                logger.info("Keywords sospechosas detectadas (usuario: $userId): $suspiciousKeywordCount")
                securityAuditLogger.logSecurityEvent(
                    userId = userId,
                    sessionId = sessionId,
                    eventType = SecurityEventType.SUSPICIOUS_PATTERN,
                    severity = SecuritySeverity.LOW,
                    description = "Keywords sospechosas: $suspiciousKeywordCount",
                    additionalData = mapOf("message" to message.take(200))
                )
            }

            // 4. Verificar repetición excesiva de caracteres especiales
            val specialCharRepetition = Regex("([!@#$%^&*()_+={}\\[\\]:;\"'<>,.?/\\\\|-])(\\1{5,})")
            if (specialCharRepetition.containsMatchIn(message)) {
                logger.warn("Repetición excesiva de caracteres especiales (usuario: $userId)")
                return@fromCallable PromptInjectionResult(
                    isInjection = true,
                    confidence = ConfidenceLevel.LOW,
                    detectedPattern = "Repetición excesiva de caracteres",
                    reason = "Patrón sospechoso de repetición de caracteres especiales"
                )
            }

            // Sin patrones de inyección detectados
            logger.debug("No se detectó prompt injection para usuario: $userId")
            PromptInjectionResult(
                isInjection = false,
                confidence = ConfidenceLevel.LOW,
                detectedPattern = null,
                reason = null
            )
        }
    }

    /**
     * Sanitiza el mensaje para mitigar prompt injection
     * Remueve patrones peligrosos manteniendo la intención original
     */
    fun sanitizeForPromptInjection(message: String): String {
        var sanitized = message

        // Remover delimitadores sospechosos
        SUSPICIOUS_DELIMITERS.forEach { regex ->
            sanitized = sanitized.replace(regex, " ")
        }

        // Normalizar espacios múltiples
        sanitized = sanitized.replace(Regex("\\s+"), " ").trim()

        return sanitized
    }
}

/**
 * Resultado de detección de prompt injection
 */
data class PromptInjectionResult(
    val isInjection: Boolean,
    val confidence: ConfidenceLevel,
    val detectedPattern: String?,
    val reason: String?
)

/**
 * Nivel de confianza en la detección
 */
enum class ConfidenceLevel {
    LOW,
    MEDIUM,
    HIGH
}
