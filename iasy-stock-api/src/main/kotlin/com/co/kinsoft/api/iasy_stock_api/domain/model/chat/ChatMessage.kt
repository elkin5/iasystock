package com.co.kinsoft.api.iasy_stock_api.domain.model.chat

import java.time.LocalDateTime

data class ChatMessage(
    val id: String? = null,
    val userId: Long,
    val message: String,
    val response: String? = null,
    val timestamp: LocalDateTime = LocalDateTime.now(),
    val status: ChatStatus = ChatStatus.PENDING
)

enum class ChatStatus {
    PENDING,
    PROCESSING,
    COMPLETED,
    ERROR
}

data class ChatRequest(
    val userId: Long,
    val message: String,
    val sessionId: String? = null, // UUID de la sesión (null para crear nueva)
    val context: Map<String, Any>? = null
)

data class ChatResponse(
    val message: String,
    val sessionId: String? = null, // UUID de la sesión para mantener contexto
    val data: Any? = null,
    val suggestions: List<String>? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
) 