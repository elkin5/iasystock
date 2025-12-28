package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat

import org.slf4j.LoggerFactory
import org.springframework.r2dbc.core.DatabaseClient
import org.springframework.stereotype.Repository
import reactor.core.publisher.Mono
import java.time.LocalDateTime
import java.util.*

@Repository
class ChatSessionRepository(
    private val databaseClient: DatabaseClient
) {

    private val logger = LoggerFactory.getLogger(ChatSessionRepository::class.java)

    /**
     * Crea una nueva sesión de chat para un usuario
     */
    fun createSession(userId: Long): Mono<ChatSession> {
        val sessionId = UUID.randomUUID()
        val now = LocalDateTime.now()

        val query = """
            INSERT INTO schmain.chat_session (session_id, created_by, status, created_at, last_interaction_at, metadata)
            VALUES (:sessionId, :createdBy, :status, :createdAt, :lastInteractionAt, :metadata::jsonb)
            RETURNING session_id, created_by, status, created_at, last_interaction_at
        """.trimIndent()

        return databaseClient.sql(query)
            .bind("sessionId", sessionId)
            .bind("createdBy", userId.toString())
            .bind("status", "ACTIVE")
            .bind("createdAt", now)
            .bind("lastInteractionAt", now)
            .bind("metadata", "{}")
            .map { row, _ ->
                ChatSession(
                    sessionId = row.get("session_id", UUID::class.java) ?: sessionId,
                    createdBy = row.get("created_by", String::class.java)?.toLongOrNull() ?: userId,
                    status = row.get("status", String::class.java) ?: "ACTIVE",
                    createdAt = row.get("created_at", LocalDateTime::class.java) ?: now,
                    lastInteractionAt = row.get("last_interaction_at", LocalDateTime::class.java) ?: now
                )
            }
            .one()
            .doOnSuccess { session ->
                logger.info("Sesión creada exitosamente: ${session.sessionId} para usuario: $userId")
            }
            .doOnError { error ->
                logger.error("Error creando sesión para usuario: $userId", error)
            }
    }

    /**
     * Obtiene una sesión por su ID
     */
    fun getSessionById(sessionId: UUID): Mono<ChatSession> {
        val query = """
            SELECT session_id, created_by, status, created_at, last_interaction_at
            FROM schmain.chat_session
            WHERE session_id = :sessionId
        """.trimIndent()

        return databaseClient.sql(query)
            .bind("sessionId", sessionId)
            .map { row, _ ->
                ChatSession(
                    sessionId = row.get("session_id", UUID::class.java) ?: sessionId,
                    createdBy = row.get("created_by", String::class.java)?.toLongOrNull() ?: 0L,
                    status = row.get("status", String::class.java) ?: "ACTIVE",
                    createdAt = row.get("created_at", LocalDateTime::class.java) ?: LocalDateTime.now(),
                    lastInteractionAt = row.get("last_interaction_at", LocalDateTime::class.java) ?: LocalDateTime.now()
                )
            }
            .one()
    }

    /**
     * Actualiza la última interacción de una sesión
     */
    fun updateLastInteraction(sessionId: UUID): Mono<Void> {
        val query = """
            UPDATE schmain.chat_session
            SET last_interaction_at = :lastInteractionAt
            WHERE session_id = :sessionId
        """.trimIndent()

        return databaseClient.sql(query)
            .bind("sessionId", sessionId)
            .bind("lastInteractionAt", LocalDateTime.now())
            .fetch()
            .rowsUpdated()
            .then()
    }

    /**
     * Guarda un mensaje en la sesión
     */
    fun saveMessage(
        sessionId: UUID,
        role: String, // "user" o "assistant"
        content: String
    ): Mono<ChatMessage> {
        val messageId = UUID.randomUUID()
        val now = LocalDateTime.now()

        val query = """
            INSERT INTO schmain.chat_message (message_id, session_id, role, content, metadata, created_at)
            VALUES (:messageId, :sessionId, :role, :content, :metadata::jsonb, :createdAt)
            RETURNING message_id, session_id, role, content, created_at
        """.trimIndent()

        return databaseClient.sql(query)
            .bind("messageId", messageId)
            .bind("sessionId", sessionId)
            .bind("role", role)
            .bind("content", content)
            .bind("metadata", "{}")
            .bind("createdAt", now)
            .map { row, _ ->
                ChatMessage(
                    messageId = row.get("message_id", UUID::class.java) ?: messageId,
                    sessionId = row.get("session_id", UUID::class.java) ?: sessionId,
                    role = row.get("role", String::class.java) ?: role,
                    content = row.get("content", String::class.java) ?: content,
                    createdAt = row.get("created_at", LocalDateTime::class.java) ?: now
                )
            }
            .one()
            .doOnSuccess {
                logger.debug("Mensaje guardado en sesión $sessionId con rol $role")
            }
    }

    /**
     * Obtiene el historial de mensajes de una sesión (ordenados cronológicamente)
     * Limita a los últimos N mensajes para no sobrecargar el contexto
     */
    fun getSessionMessages(sessionId: UUID, limit: Int = 20): Mono<List<ChatMessage>> {
        val query = """
            SELECT message_id, session_id, role, content, created_at
            FROM schmain.chat_message
            WHERE session_id = :sessionId
            ORDER BY created_at DESC
            LIMIT :limit
        """.trimIndent()

        return databaseClient.sql(query)
            .bind("sessionId", sessionId)
            .bind("limit", limit)
            .map { row, _ ->
                ChatMessage(
                    messageId = row.get("message_id", UUID::class.java) ?: UUID.randomUUID(),
                    sessionId = row.get("session_id", UUID::class.java) ?: sessionId,
                    role = row.get("role", String::class.java) ?: "",
                    content = row.get("content", String::class.java) ?: "",
                    createdAt = row.get("created_at", LocalDateTime::class.java) ?: LocalDateTime.now()
                )
            }
            .all()
            .collectList()
            .map { messages ->
                // Invertir para que queden en orden cronológico (más antiguos primero)
                messages.reversed()
            }
            .doOnSuccess { messages ->
                logger.debug("Recuperados ${messages.size} mensajes de la sesión $sessionId")
            }
    }

    /**
     * Obtiene la sesión más reciente de un usuario
     */
    fun getLatestUserSession(userId: Long): Mono<ChatSession> {
        val query = """
            SELECT session_id, created_by, status, created_at, last_interaction_at
            FROM schmain.chat_session
            WHERE created_by = :createdBy
            AND status = 'ACTIVE'
            ORDER BY last_interaction_at DESC
            LIMIT 1
        """.trimIndent()

        return databaseClient.sql(query)
            .bind("createdBy", userId.toString())
            .map { row, _ ->
                ChatSession(
                    sessionId = row.get("session_id", UUID::class.java) ?: UUID.randomUUID(),
                    createdBy = row.get("created_by", String::class.java)?.toLongOrNull() ?: userId,
                    status = row.get("status", String::class.java) ?: "ACTIVE",
                    createdAt = row.get("created_at", LocalDateTime::class.java) ?: LocalDateTime.now(),
                    lastInteractionAt = row.get("last_interaction_at", LocalDateTime::class.java) ?: LocalDateTime.now()
                )
            }
            .one()
            .doOnSuccess { session ->
                logger.debug("Recuperada sesión más reciente para usuario $userId: ${session.sessionId}")
            }
    }
}

/**
 * Modelo de sesión de chat
 */
data class ChatSession(
    val sessionId: UUID,
    val createdBy: Long,
    val status: String,
    val createdAt: LocalDateTime,
    val lastInteractionAt: LocalDateTime
)

/**
 * Modelo de mensaje de chat
 */
data class ChatMessage(
    val messageId: UUID,
    val sessionId: UUID,
    val role: String, // "user" o "assistant"
    val content: String,
    val createdAt: LocalDateTime
)
