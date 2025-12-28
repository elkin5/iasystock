package com.co.kinsoft.api.iasy_stock_api.config

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.DomainException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.ErrorContext
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.ErrorResponse
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.ErrorResponseSimple
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import org.slf4j.LoggerFactory
import org.slf4j.MDC
import org.springframework.beans.factory.annotation.Value
import org.springframework.core.annotation.Order
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.server.ServerWebExchange
import org.springframework.web.server.ServerWebInputException
import org.springframework.web.server.ResponseStatusException
import org.springframework.web.server.WebExceptionHandler
import reactor.core.publisher.Mono
import java.time.LocalDateTime
import java.util.*

@Component
@Order(-2)
class GlobalErrorHandler(
    @Value("\${spring.profiles.active:dev}") private val activeProfile: String
) : WebExceptionHandler {

    private val logger = LoggerFactory.getLogger(GlobalErrorHandler::class.java)
    private val isDevelopment = activeProfile.contains("dev")

    private val objectMapper: ObjectMapper = ObjectMapper()
        .registerModule(JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)

    override fun handle(exchange: ServerWebExchange, ex: Throwable): Mono<Void> {
        val response = exchange.response
        response.headers.contentType = MediaType.APPLICATION_JSON

        // Extraer contexto del error
        val context = ErrorHandlingUtils.extractErrorContext(exchange)
        val requestId = context.requestId ?: UUID.randomUUID().toString()
        
        // Configurar MDC para logging estructurado
        MDC.put("requestId", requestId)
        MDC.put("path", exchange.request.path.toString())
        MDC.put("method", exchange.request.method?.name() ?: "UNKNOWN")
        MDC.put("exceptionType", ex.javaClass.simpleName)

        // Determinar status y mensaje
        val (status, message, errorCode) = determineErrorDetails(ex, exchange)
        
        // Logging estructurado del error
        logError(ex, context, status, message)

        response.statusCode = status

        // Crear respuesta de error
        val errorResponse = createErrorResponse(ex, exchange, context, status, message, errorCode)

        val buffer = response.bufferFactory().wrap(objectMapper.writeValueAsBytes(errorResponse))
        
        return response.writeWith(Mono.just(buffer))
            .doFinally { 
                // Limpiar MDC
                MDC.clear() 
            }
    }

    private fun determineErrorDetails(ex: Throwable, exchange: ServerWebExchange): Triple<HttpStatus, String, String> {
        return when (ex) {
            is NotFoundException -> Triple(HttpStatus.NOT_FOUND, ex.message ?: "Recurso no encontrado", "NOT_FOUND")
            is InvalidDataException -> Triple(HttpStatus.BAD_REQUEST, ex.message ?: "Datos inválidos", "INVALID_DATA")
            is AlreadyExistsException -> Triple(HttpStatus.CONFLICT, ex.message ?: "Recurso ya existe", "ALREADY_EXISTS")
            is DomainException -> Triple(HttpStatus.UNPROCESSABLE_ENTITY, ex.message ?: "Error de dominio", "DOMAIN_ERROR")
            is ServerWebInputException -> {
                val message = when {
                    ex.message?.contains("Failed to read HTTP message") == true -> 
                        "Error al procesar el request: formato de datos inválido"
                    ex.message?.contains("Required request body is missing") == true -> 
                        "El request requiere un body con datos"
                    ex.message?.contains("JSON parse error") == true -> 
                        "Error de formato JSON en el request"
                    else -> "Error en el procesamiento del input del request"
                }
                Triple(HttpStatus.BAD_REQUEST, message, "INPUT_ERROR")
            }
            is ResponseStatusException -> Triple(
                HttpStatus.valueOf(ex.statusCode.value()), 
                ex.reason ?: "Error de respuesta", 
                "RESPONSE_ERROR"
            )
            is org.springframework.security.core.AuthenticationException -> Triple(
                HttpStatus.UNAUTHORIZED, 
                "Error de autenticación: ${ex.message}", 
                "AUTH_ERROR"
            )
            is org.springframework.security.access.AccessDeniedException -> Triple(
                HttpStatus.FORBIDDEN, 
                "Acceso denegado: no tienes permisos para realizar esta acción", 
                "ACCESS_DENIED"
            )
            else -> Triple(
                HttpStatus.INTERNAL_SERVER_ERROR, 
                "Error interno del servidor", 
                "INTERNAL_ERROR"
            )
        }
    }

    private fun logError(ex: Throwable, context: ErrorContext, status: HttpStatus, message: String) {
        val logMessage = buildString {
            append("🚨 ERROR [${status.value()}] - $message")
            append(" | RequestId: ${context.requestId}")
            append(" | Path: ${context.method} ${context.requestId}")
            if (context.userAgent != null) {
                append(" | UserAgent: ${context.userAgent}")
            }
        }

        when {
            status.is4xxClientError -> logger.warn(logMessage, ex)
            status.is5xxServerError -> logger.error(logMessage, ex)
            else -> logger.info(logMessage, ex)
        }

        // Log adicional con contexto completo en desarrollo
        if (isDevelopment) {
            logger.debug("""
                📋 ERROR CONTEXT:
                ├─ RequestId: ${context.requestId}
                ├─ Method: ${context.method}
                ├─ UserAgent: ${context.userAgent}
                ├─ QueryParams: ${context.queryParams}
                ├─ CorrelationId: ${context.correlationId}
                └─ Exception: ${ex.javaClass.name}
            """.trimIndent())
        }
    }

    private fun createErrorResponse(
        ex: Throwable, 
        exchange: ServerWebExchange, 
        context: ErrorContext,
        status: HttpStatus, 
        message: String, 
        errorCode: String
    ): Any {
        val path = exchange.request.path.toString()
        val requestId = context.requestId ?: UUID.randomUUID().toString()
        val timestamp = LocalDateTime.now()

        return if (isDevelopment) {
            // Respuesta detallada para desarrollo
            ErrorResponse(
                timestamp = timestamp,
                status = status.value(),
                error = status.reasonPhrase,
                message = message,
                path = path,
                requestId = requestId,
                errorCode = ErrorHandlingUtils.generateErrorCode(ex, path),
                details = ErrorHandlingUtils.generateErrorDetails(ex, context),
                stackTrace = if (ErrorHandlingUtils.shouldShowStackTrace(ex, isDevelopment)) {
                    ErrorHandlingUtils.getStackTraceAsString(ex)
                } else null,
                suggestions = ErrorHandlingUtils.generateSuggestions(ex, path)
            )
        } else {
            // Respuesta simplificada para producción
            ErrorResponseSimple(
                timestamp = timestamp,
                status = status.value(),
                error = status.reasonPhrase,
                message = message,
                path = path,
                requestId = requestId,
                errorCode = ErrorHandlingUtils.generateErrorCode(ex, path)
            )
        }
    }
}