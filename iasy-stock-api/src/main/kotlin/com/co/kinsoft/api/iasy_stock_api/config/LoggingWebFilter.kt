package com.co.kinsoft.api.iasy_stock_api.config

import org.slf4j.MDC
import org.springframework.stereotype.Component
import org.springframework.web.server.ServerWebExchange
import org.springframework.web.server.WebFilter
import org.springframework.web.server.WebFilterChain
import reactor.core.publisher.Mono
import java.util.*

@Component
class LoggingWebFilter : WebFilter {

    companion object {
        private const val REQUEST_ID = "requestId"
        private const val CORRELATION_ID = "correlationId"
        private const val USER_ID = "userId"
    }

    override fun filter(exchange: ServerWebExchange, chain: WebFilterChain): Mono<Void> {
        val requestId = UUID.randomUUID().toString()
        val correlationId = exchange.request.headers.getFirst("X-Correlation-ID") ?: UUID.randomUUID().toString()
        
        // Extraer userId del JWT si está disponible (opcional)
        val userId = extractUserIdFromRequest(exchange)
        
        // Configurar atributos del exchange
        exchange.attributes[REQUEST_ID] = requestId
        exchange.attributes[CORRELATION_ID] = correlationId
        if (userId != null) {
            exchange.attributes[USER_ID] = userId
        }

        return chain.filter(exchange)
            .contextWrite { ctx -> 
                ctx.put(REQUEST_ID, requestId)
                    .put(CORRELATION_ID, correlationId)
                    .put(USER_ID, userId ?: "anonymous")
            }
            .doFirst { 
                // Configurar MDC para logging estructurado
                MDC.put(REQUEST_ID, requestId)
                MDC.put(CORRELATION_ID, correlationId)
                if (userId != null) {
                    MDC.put(USER_ID, userId)
                }
                MDC.put("method", exchange.request.method?.name() ?: "UNKNOWN")
                MDC.put("path", exchange.request.path.toString())
                MDC.put("userAgent", exchange.request.headers.getFirst("User-Agent") ?: "Unknown")
            }
            .doFinally { 
                // Limpiar MDC
                MDC.clear() 
            }
    }

    private fun extractUserIdFromRequest(exchange: ServerWebExchange): String? {
        // Intentar extraer userId del header Authorization si está disponible
        val authHeader = exchange.request.headers.getFirst("Authorization")
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            // En un escenario real, aquí decodificarías el JWT para extraer el userId
            // Por ahora, retornamos null para mantener la funcionalidad básica
            return null
        }
        return null
    }
}