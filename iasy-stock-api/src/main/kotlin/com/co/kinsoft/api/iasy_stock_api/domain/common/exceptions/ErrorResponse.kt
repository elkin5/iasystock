package com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions

import com.fasterxml.jackson.annotation.JsonFormat
import com.fasterxml.jackson.annotation.JsonInclude
import java.time.LocalDateTime

/**
 * Respuesta de error mejorada con información detallada para debugging
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class ErrorResponse(
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    val timestamp: LocalDateTime,
    val status: Int,
    val error: String,
    val message: String,
    val path: String,
    val requestId: String? = null,
    val errorCode: String? = null,
    val details: Map<String, Any>? = null,
    val stackTrace: String? = null,
    val suggestions: List<String>? = null
)

/**
 * Respuesta de error simplificada para producción
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class ErrorResponseSimple(
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    val timestamp: LocalDateTime,
    val status: Int,
    val error: String,
    val message: String,
    val path: String,
    val requestId: String? = null,
    val errorCode: String? = null
)

/**
 * Información adicional de contexto para errores
 */
data class ErrorContext(
    val requestId: String? = null,
    val userId: String? = null,
    val userAgent: String? = null,
    val method: String? = null,
    val queryParams: Map<String, String>? = null,
    val requestBody: String? = null,
    val correlationId: String? = null
)