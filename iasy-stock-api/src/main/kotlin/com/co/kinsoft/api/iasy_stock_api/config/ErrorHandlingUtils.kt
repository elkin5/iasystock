package com.co.kinsoft.api.iasy_stock_api.config

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.ErrorContext
import org.springframework.web.server.ServerWebExchange
import java.io.PrintWriter
import java.io.StringWriter
import java.time.LocalDateTime
import java.util.*

/**
 * Utilidades para el manejo de errores
 */
object ErrorHandlingUtils {

    /**
     * Extrae el contexto de la request para debugging
     */
    fun extractErrorContext(exchange: ServerWebExchange): ErrorContext {
        val request = exchange.request
        val requestId = exchange.attributes["requestId"] as? String ?: UUID.randomUUID().toString()
        
        return ErrorContext(
            requestId = requestId,
            userAgent = request.headers.getFirst("User-Agent"),
            method = request.method?.name(),
            queryParams = request.queryParams.toSingleValueMap(),
            correlationId = request.headers.getFirst("X-Correlation-ID")
        )
    }

    /**
     * Convierte el stacktrace a string legible
     */
    fun getStackTraceAsString(throwable: Throwable): String {
        val stringWriter = StringWriter()
        val printWriter = PrintWriter(stringWriter)
        throwable.printStackTrace(printWriter)
        return stringWriter.toString()
    }

    /**
     * Genera sugerencias basadas en el tipo de error
     */
    fun generateSuggestions(throwable: Throwable, path: String): List<String> {
        return when {
            throwable.message?.contains("Failed to read HTTP message") == true -> listOf(
                "Verificar que el JSON enviado sea válido",
                "Revisar el Content-Type del request (debe ser application/json)",
                "Verificar que el tamaño del request no exceda los límites configurados"
            )
            throwable.message?.contains("Required request body is missing") == true -> listOf(
                "El endpoint requiere un body en el request",
                "Verificar que se esté enviando data en el request",
                "Revisar la documentación del endpoint"
            )
            throwable.message?.contains("JSON parse error") == true -> listOf(
                "El JSON enviado tiene formato inválido",
                "Usar un validador JSON online para verificar la sintaxis",
                "Revisar caracteres especiales o comillas mal formateadas"
            )
            throwable.message?.contains("Validation failed") == true -> listOf(
                "Revisar los campos requeridos en el request",
                "Verificar los tipos de datos enviados",
                "Consultar la documentación de validación del endpoint"
            )
            path.contains("/auth") -> listOf(
                "Verificar que el token JWT sea válido",
                "Revisar que el usuario tenga los permisos necesarios",
                "Comprobar que el token no haya expirado"
            )
            else -> listOf(
                "Revisar los logs del servidor para más detalles",
                "Verificar que todos los servicios dependientes estén funcionando",
                "Contactar al equipo de desarrollo si el problema persiste"
            )
        }
    }

    /**
     * Genera detalles adicionales del error
     */
    fun generateErrorDetails(throwable: Throwable, context: ErrorContext): Map<String, Any> {
        val details = mutableMapOf<String, Any>()
        
        details["exceptionType"] = throwable.javaClass.simpleName
        details["exceptionMessage"] = throwable.message ?: "Sin mensaje"
        
        if (context.requestId != null) {
            details["requestId"] = context.requestId
        }
        
        if (context.method != null) {
            details["httpMethod"] = context.method
        }
        
        if (context.userAgent != null) {
            details["userAgent"] = context.userAgent
        }
        
        if (context.queryParams?.isNotEmpty() == true) {
            details["queryParams"] = context.queryParams
        }
        
        // Agregar información específica según el tipo de error
        when (throwable) {
            is org.springframework.web.server.ServerWebInputException -> {
                details["inputError"] = "Error en el procesamiento del input"
                details["possibleCause"] = "Formato de datos inválido o campos faltantes"
            }
            is org.springframework.web.server.ResponseStatusException -> {
                details["statusCode"] = throwable.statusCode.value()
                details["reason"] = throwable.reason ?: "Sin razón especificada"
            }
            is org.springframework.security.core.AuthenticationException -> {
                details["authError"] = "Error de autenticación"
                details["authType"] = throwable.javaClass.simpleName
            }
            is org.springframework.security.access.AccessDeniedException -> {
                details["accessError"] = "Acceso denegado"
                details["requiredAuthority"] = "Revisar permisos del usuario"
            }
        }
        
        return details
    }

    /**
     * Determina si se debe mostrar el stacktrace completo
     */
    fun shouldShowStackTrace(throwable: Throwable, isDevelopment: Boolean): Boolean {
        return isDevelopment || 
               throwable is org.springframework.web.server.ServerWebInputException ||
               throwable is org.springframework.web.server.ResponseStatusException
    }

    /**
     * Genera un código de error único para tracking
     */
    fun generateErrorCode(throwable: Throwable, path: String): String {
        val timestamp = LocalDateTime.now()
        val hour = timestamp.hour.toString().padStart(2, '0')
        val minute = timestamp.minute.toString().padStart(2, '0')
        val exceptionType = throwable.javaClass.simpleName.take(3).uppercase()
        val pathHash = path.hashCode().toString().takeLast(3)
        
        return "ERR-${hour}${minute}-${exceptionType}-${pathHash}"
    }
}
