package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.chat

import com.co.kinsoft.api.iasy_stock_api.domain.model.chat.ChatRequest
import com.co.kinsoft.api.iasy_stock_api.domain.model.chat.ChatResponse
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.ChatUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.InputValidationUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.PromptInjectionDetector
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.RateLimitingService
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.SecurityAuditLogger
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.SecurityEventType
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security.SecuritySeverity
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.SimpleOpenAIService
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.time.LocalDateTime

@Component
class ChatHandler(
    private val chatUseCase: ChatUseCase,
    private val openAIService: SimpleOpenAIService,
    private val rateLimitingService: RateLimitingService,
    private val inputValidationUseCase: InputValidationUseCase,
    private val promptInjectionDetector: PromptInjectionDetector,
    private val securityAuditLogger: SecurityAuditLogger
) {

    private val logger = LoggerFactory.getLogger(ChatHandler::class.java)

    fun processMessage(request: ServerRequest): Mono<ServerResponse> {
        // Extraer IP del request
        val ipAddress = request.remoteAddress().map { it.address.hostAddress }.orElse("unknown")

        return request.bodyToMono(ChatRequest::class.java)
            .flatMap { chatRequest ->
                logger.info("Procesando mensaje del chat para usuario: ${chatRequest.userId}, IP: $ipAddress")

                // 1. Verificar rate limiting
                rateLimitingService.checkRateLimit(chatRequest.userId, ipAddress, chatRequest.sessionId)
                    .flatMap { rateLimitResult ->
                        if (!rateLimitResult.allowed) {
                            logger.warn("Rate limit excedido para usuario: ${chatRequest.userId}")
                            return@flatMap ServerResponse.status(HttpStatus.TOO_MANY_REQUESTS)
                                .contentType(MediaType.APPLICATION_JSON)
                                .bodyValue(
                                    mapOf(
                                        "error" to "RATE_LIMIT_EXCEEDED",
                                        "message" to rateLimitResult.reason,
                                        "retryAfterSeconds" to rateLimitResult.retryAfterSeconds,
                                        "timestamp" to LocalDateTime.now()
                                    )
                                )
                        }

                        // 2. Validar y sanitizar input
                        inputValidationUseCase.validateAndSanitize(
                            chatRequest.message,
                            chatRequest.userId,
                            chatRequest.sessionId
                        ).flatMap { inputValidation ->
                            if (!inputValidation.isValid) {
                                logger.warn("Validación de input fallida para usuario: ${chatRequest.userId} - ${inputValidation.reason}")
                                return@flatMap ServerResponse.badRequest()
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .bodyValue(
                                        mapOf(
                                            "error" to "INVALID_INPUT",
                                            "message" to (inputValidation.reason ?: "El mensaje contiene contenido no permitido"),
                                            "violationType" to inputValidation.violationType.toString(),
                                            "timestamp" to LocalDateTime.now()
                                        )
                                    )
                            }

                            // 3. Detectar prompt injection
                            promptInjectionDetector.detectPromptInjection(
                                inputValidation.sanitizedMessage!!,
                                chatRequest.userId,
                                chatRequest.sessionId
                            ).flatMap { injectionResult ->
                                if (injectionResult.isInjection) {
                                    logger.warn("Prompt injection detectado para usuario: ${chatRequest.userId} - ${injectionResult.reason}")

                                    // Si la confianza es alta, bloquear directamente
                                    if (injectionResult.confidence.name == "HIGH") {
                                        return@flatMap ServerResponse.badRequest()
                                            .contentType(MediaType.APPLICATION_JSON)
                                            .bodyValue(
                                                mapOf(
                                                    "error" to "SECURITY_VIOLATION",
                                                    "message" to "Tu mensaje contiene patrones que no están permitidos por razones de seguridad",
                                                    "timestamp" to LocalDateTime.now()
                                                )
                                            )
                                    }

                                    // Si es confianza media/baja, registrar pero permitir (con sanitización)
                                    securityAuditLogger.logSecurityEvent(
                                        userId = chatRequest.userId,
                                        sessionId = chatRequest.sessionId,
                                        eventType = SecurityEventType.SUSPICIOUS_PATTERN,
                                        severity = SecuritySeverity.MEDIUM,
                                        description = "Posible prompt injection detectado (confianza: ${injectionResult.confidence})",
                                        additionalData = mapOf("message" to inputValidation.sanitizedMessage.take(200))
                                    )
                                }

                                // 4. Procesar mensaje con el mensaje sanitizado
                                val sanitizedRequest = chatRequest.copy(message = inputValidation.sanitizedMessage)
                                chatUseCase.processMessage(sanitizedRequest)
                                    .flatMap { response ->
                                        ServerResponse.ok()
                                            .contentType(MediaType.APPLICATION_JSON)
                                            .bodyValue(response)
                                    }
                            }
                        }
                    }
            }
            .onErrorResume { error ->
                logger.error("Error procesando mensaje del chat", error)
                val errorResponse = ChatResponse(
                    message = "Lo siento, tuve un problema procesando tu consulta. ¿Podrías reformularla?",
                    data = null,
                    suggestions = listOf(
                        "¿Cuántos productos tengo en stock?",
                        "¿Cuáles son mis productos más vendidos?",
                        "¿Qué productos están por vencer?"
                    ),
                    timestamp = LocalDateTime.now()
                )

                ServerResponse.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(errorResponse)
            }
    }
} 