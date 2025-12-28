package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Logger especializado para eventos de seguridad
 * Registra y audita intentos de ataques y violaciones de seguridad
 */
@Service
class SecurityAuditLogger {

    private val logger = LoggerFactory.getLogger(SecurityAuditLogger::class.java)
    private val securityLogger = LoggerFactory.getLogger("SECURITY_AUDIT")

    /**
     * Registra un evento de seguridad de forma reactiva
     */
    fun logSecurityEventAsync(
        userId: Long,
        sessionId: String?,
        eventType: SecurityEventType,
        severity: SecuritySeverity,
        description: String,
        additionalData: Map<String, Any>? = null
    ): Mono<Unit> {
        return Mono.fromCallable {
            logSecurityEvent(userId, sessionId, eventType, severity, description, additionalData)
        }
    }

    /**
     * Registra un evento de seguridad
     */
    fun logSecurityEvent(
        userId: Long,
        sessionId: String?,
        eventType: SecurityEventType,
        severity: SecuritySeverity,
        description: String,
        additionalData: Map<String, Any>? = null
    ) {
        val event = SecurityEvent(
            timestamp = LocalDateTime.now(),
            userId = userId,
            sessionId = sessionId,
            eventType = eventType,
            severity = severity,
            description = description,
            additionalData = additionalData
        )

        // Log según severidad
        when (severity) {
            SecuritySeverity.CRITICAL -> {
                securityLogger.error(formatSecurityEvent(event))
                logger.error("SECURITY ALERT: {}", event)
            }
            SecuritySeverity.HIGH -> {
                securityLogger.warn(formatSecurityEvent(event))
                logger.warn("Security event: {}", event)
            }
            SecuritySeverity.MEDIUM -> {
                securityLogger.info(formatSecurityEvent(event))
                logger.info("Security event: {}", event)
            }
            SecuritySeverity.LOW -> {
                securityLogger.debug(formatSecurityEvent(event))
                logger.debug("Security event: {}", event)
            }
        }
    }

    /**
     * Registra un intento de ataque detectado
     */
    fun logAttackAttempt(
        userId: Long,
        sessionId: String?,
        attackType: String,
        details: String,
        payload: String? = null
    ) {
        logSecurityEvent(
            userId = userId,
            sessionId = sessionId,
            eventType = SecurityEventType.ATTACK_DETECTED,
            severity = SecuritySeverity.HIGH,
            description = "Intento de ataque detectado: $attackType - $details",
            additionalData = mapOf(
                "attackType" to attackType,
                "details" to details,
                "payload" to (payload?.take(500) ?: "N/A")
            )
        )
    }

    /**
     * Registra violación de rate limiting
     */
    fun logRateLimitViolation(
        userId: Long?,
        ipAddress: String?,
        sessionId: String?,
        requestCount: Int,
        windowSeconds: Int
    ) {
        logSecurityEvent(
            userId = userId ?: -1,
            sessionId = sessionId,
            eventType = SecurityEventType.RATE_LIMIT_EXCEEDED,
            severity = SecuritySeverity.MEDIUM,
            description = "Rate limit excedido: $requestCount requests en $windowSeconds segundos",
            additionalData = mapOf(
                "ipAddress" to (ipAddress ?: "unknown"),
                "requestCount" to requestCount,
                "windowSeconds" to windowSeconds
            )
        )
    }

    /**
     * Registra query SQL bloqueado
     */
    fun logBlockedSqlQuery(
        userId: Long,
        sessionId: String?,
        query: String,
        reason: String
    ) {
        logSecurityEvent(
            userId = userId,
            sessionId = sessionId,
            eventType = SecurityEventType.SQL_QUERY_BLOCKED,
            severity = SecuritySeverity.HIGH,
            description = "Query SQL bloqueado: $reason",
            additionalData = mapOf(
                "query" to query.take(500),
                "reason" to reason
            )
        )
    }

    /**
     * Formatea el evento para el log
     */
    private fun formatSecurityEvent(event: SecurityEvent): String {
        return buildString {
            append("[${event.severity}] ")
            append("${event.eventType} | ")
            append("User: ${event.userId} | ")
            append("Session: ${event.sessionId ?: "N/A"} | ")
            append("${event.description}")
            if (!event.additionalData.isNullOrEmpty()) {
                append(" | Data: ${event.additionalData}")
            }
        }
    }
}

/**
 * Evento de seguridad
 */
data class SecurityEvent(
    val timestamp: LocalDateTime,
    val userId: Long,
    val sessionId: String?,
    val eventType: SecurityEventType,
    val severity: SecuritySeverity,
    val description: String,
    val additionalData: Map<String, Any>?
)

/**
 * Tipos de eventos de seguridad
 */
enum class SecurityEventType {
    INPUT_VALIDATION_FAILED,
    SQL_INJECTION_ATTEMPT,
    PROMPT_INJECTION_ATTEMPT,
    XSS_ATTEMPT,
    RATE_LIMIT_EXCEEDED,
    SUSPICIOUS_PATTERN,
    ATTACK_DETECTED,
    SQL_QUERY_BLOCKED,
    UNAUTHORIZED_ACCESS,
    SCHEMA_VIOLATION,
    EXCESSIVE_REQUESTS
}

/**
 * Niveles de severidad
 */
enum class SecuritySeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}
