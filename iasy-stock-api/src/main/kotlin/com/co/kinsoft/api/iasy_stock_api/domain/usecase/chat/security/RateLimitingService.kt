package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

/**
 * Servicio de rate limiting para prevenir abuso y ataques DoS
 * Implementa limitación por usuario y por IP
 */
@Service
class RateLimitingService(
    private val securityAuditLogger: SecurityAuditLogger
) {

    private val logger = LoggerFactory.getLogger(RateLimitingService::class.java)

    // Almacenamiento en memoria de requests por usuario
    private val userRequestCounts = ConcurrentHashMap<String, RequestWindow>()

    // Almacenamiento en memoria de requests por IP
    private val ipRequestCounts = ConcurrentHashMap<String, RequestWindow>()

    companion object {
        // Configuración de rate limits
        const val MAX_REQUESTS_PER_USER_PER_MINUTE = 10
        const val MAX_REQUESTS_PER_USER_PER_HOUR = 100
        const val MAX_REQUESTS_PER_IP_PER_MINUTE = 20
        const val MAX_REQUESTS_PER_IP_PER_HOUR = 200

        const val WINDOW_SIZE_MINUTES = 1L
        const val WINDOW_SIZE_HOURS = 60L

        // Tiempo de bloqueo en segundos cuando se excede el límite
        const val BLOCK_DURATION_SECONDS = 60L
    }

    /**
     * Verifica si el usuario/IP puede hacer un request
     */
    fun checkRateLimit(
        userId: Long,
        ipAddress: String?,
        sessionId: String?
    ): Mono<RateLimitResult> {
        return Mono.fromCallable {
            logger.debug("Verificando rate limit para usuario: $userId, IP: $ipAddress")

            // Limpiar ventanas expiradas periódicamente
            cleanupExpiredWindows()

            // 1. Verificar rate limit por usuario
            val userKey = "user:$userId"
            val userCheck = checkLimit(
                key = userKey,
                maxPerMinute = MAX_REQUESTS_PER_USER_PER_MINUTE,
                maxPerHour = MAX_REQUESTS_PER_USER_PER_HOUR,
                storage = userRequestCounts
            )

            if (!userCheck.allowed) {
                logger.warn("Rate limit excedido para usuario: $userId")
                securityAuditLogger.logRateLimitViolation(
                    userId = userId,
                    ipAddress = ipAddress,
                    sessionId = sessionId,
                    requestCount = userCheck.currentCount,
                    windowSeconds = userCheck.windowSeconds
                )

                return@fromCallable RateLimitResult(
                    allowed = false,
                    reason = "Has excedido el límite de consultas. Por favor espera ${userCheck.retryAfterSeconds} segundos.",
                    retryAfterSeconds = userCheck.retryAfterSeconds,
                    remainingRequests = 0,
                    limitType = LimitType.USER_LIMIT
                )
            }

            // 2. Verificar rate limit por IP (si está disponible)
            if (!ipAddress.isNullOrBlank()) {
                val ipKey = "ip:$ipAddress"
                val ipCheck = checkLimit(
                    key = ipKey,
                    maxPerMinute = MAX_REQUESTS_PER_IP_PER_MINUTE,
                    maxPerHour = MAX_REQUESTS_PER_IP_PER_HOUR,
                    storage = ipRequestCounts
                )

                if (!ipCheck.allowed) {
                    logger.warn("Rate limit excedido para IP: $ipAddress")
                    securityAuditLogger.logRateLimitViolation(
                        userId = userId,
                        ipAddress = ipAddress,
                        sessionId = sessionId,
                        requestCount = ipCheck.currentCount,
                        windowSeconds = ipCheck.windowSeconds
                    )

                    return@fromCallable RateLimitResult(
                        allowed = false,
                        reason = "Se han detectado demasiadas consultas desde tu red. Por favor espera ${ipCheck.retryAfterSeconds} segundos.",
                        retryAfterSeconds = ipCheck.retryAfterSeconds,
                        remainingRequests = 0,
                        limitType = LimitType.IP_LIMIT
                    )
                }
            }

            // 3. Incrementar contadores si todo está OK
            incrementCounter(userKey, userRequestCounts)
            if (!ipAddress.isNullOrBlank()) {
                incrementCounter("ip:$ipAddress", ipRequestCounts)
            }

            logger.debug("Rate limit OK para usuario: $userId")
            RateLimitResult(
                allowed = true,
                reason = null,
                retryAfterSeconds = 0,
                remainingRequests = MAX_REQUESTS_PER_USER_PER_MINUTE - userCheck.currentCount - 1,
                limitType = null
            )
        }
    }

    /**
     * Verifica límites para una clave específica
     */
    private fun checkLimit(
        key: String,
        maxPerMinute: Int,
        maxPerHour: Int,
        storage: ConcurrentHashMap<String, RequestWindow>
    ): LimitCheckResult {
        val now = Instant.now()
        val window = storage.getOrPut(key) { RequestWindow() }

        synchronized(window) {
            // Limpiar requests antiguos
            window.cleanupOldRequests(now)

            // Verificar si está bloqueado
            if (window.isBlocked(now)) {
                val retryAfter = window.blockUntil!!.epochSecond - now.epochSecond
                return LimitCheckResult(
                    allowed = false,
                    currentCount = window.requestTimestamps.size,
                    retryAfterSeconds = retryAfter.toInt(),
                    windowSeconds = 60
                )
            }

            // Contar requests en la última minuto
            val requestsLastMinute = window.countRequestsInWindow(now, WINDOW_SIZE_MINUTES)
            if (requestsLastMinute >= maxPerMinute) {
                // Bloquear temporalmente
                window.blockUntil = now.plusSeconds(BLOCK_DURATION_SECONDS)

                return LimitCheckResult(
                    allowed = false,
                    currentCount = requestsLastMinute,
                    retryAfterSeconds = BLOCK_DURATION_SECONDS.toInt(),
                    windowSeconds = 60
                )
            }

            // Contar requests en la última hora
            val requestsLastHour = window.countRequestsInWindow(now, WINDOW_SIZE_HOURS)
            if (requestsLastHour >= maxPerHour) {
                // Bloquear temporalmente
                window.blockUntil = now.plusSeconds(BLOCK_DURATION_SECONDS * 5) // 5 minutos para límite horario

                return LimitCheckResult(
                    allowed = false,
                    currentCount = requestsLastHour,
                    retryAfterSeconds = (BLOCK_DURATION_SECONDS * 5).toInt(),
                    windowSeconds = 3600
                )
            }

            return LimitCheckResult(
                allowed = true,
                currentCount = requestsLastMinute,
                retryAfterSeconds = 0,
                windowSeconds = 60
            )
        }
    }

    /**
     * Incrementa el contador de requests
     */
    private fun incrementCounter(key: String, storage: ConcurrentHashMap<String, RequestWindow>) {
        val window = storage.getOrPut(key) { RequestWindow() }
        synchronized(window) {
            window.addRequest(Instant.now())
        }
    }

    /**
     * Limpia ventanas expiradas para liberar memoria
     */
    private fun cleanupExpiredWindows() {
        val now = Instant.now()
        val expirationThreshold = now.minusSeconds(3600) // 1 hora

        userRequestCounts.entries.removeIf { (_, window) ->
            synchronized(window) {
                window.requestTimestamps.isEmpty() ||
                window.requestTimestamps.last().isBefore(expirationThreshold)
            }
        }

        ipRequestCounts.entries.removeIf { (_, window) ->
            synchronized(window) {
                window.requestTimestamps.isEmpty() ||
                window.requestTimestamps.last().isBefore(expirationThreshold)
            }
        }
    }

    /**
     * Resetea el rate limit para un usuario (útil para testing o admin override)
     */
    fun resetUserLimit(userId: Long) {
        val key = "user:$userId"
        userRequestCounts.remove(key)
        logger.info("Rate limit reseteado para usuario: $userId")
    }

    /**
     * Obtiene estadísticas de rate limiting para un usuario
     */
    fun getUserStats(userId: Long): RateLimitStats {
        val key = "user:$userId"
        val window = userRequestCounts[key] ?: return RateLimitStats(
            requestsLastMinute = 0,
            requestsLastHour = 0,
            isBlocked = false,
            blockedUntil = null
        )

        val now = Instant.now()
        synchronized(window) {
            return RateLimitStats(
                requestsLastMinute = window.countRequestsInWindow(now, WINDOW_SIZE_MINUTES),
                requestsLastHour = window.countRequestsInWindow(now, WINDOW_SIZE_HOURS),
                isBlocked = window.isBlocked(now),
                blockedUntil = window.blockUntil
            )
        }
    }
}

/**
 * Ventana de requests para tracking
 */
class RequestWindow {
    val requestTimestamps = mutableListOf<Instant>()
    var blockUntil: Instant? = null

    fun addRequest(timestamp: Instant) {
        requestTimestamps.add(timestamp)
    }

    fun cleanupOldRequests(now: Instant) {
        val hourAgo = now.minusSeconds(3600)
        requestTimestamps.removeIf { it.isBefore(hourAgo) }
    }

    fun countRequestsInWindow(now: Instant, windowMinutes: Long): Int {
        val windowStart = now.minusSeconds(windowMinutes * 60)
        return requestTimestamps.count { it.isAfter(windowStart) }
    }

    fun isBlocked(now: Instant): Boolean {
        return blockUntil?.isAfter(now) == true
    }
}

/**
 * Resultado de verificación de límite
 */
data class LimitCheckResult(
    val allowed: Boolean,
    val currentCount: Int,
    val retryAfterSeconds: Int,
    val windowSeconds: Int
)

/**
 * Resultado de rate limiting
 */
data class RateLimitResult(
    val allowed: Boolean,
    val reason: String?,
    val retryAfterSeconds: Int,
    val remainingRequests: Int,
    val limitType: LimitType?
)

/**
 * Tipo de límite excedido
 */
enum class LimitType {
    USER_LIMIT,
    IP_LIMIT
}

/**
 * Estadísticas de rate limiting
 */
data class RateLimitStats(
    val requestsLastMinute: Int,
    val requestsLastHour: Int,
    val isBlocked: Boolean,
    val blockedUntil: Instant?
)
