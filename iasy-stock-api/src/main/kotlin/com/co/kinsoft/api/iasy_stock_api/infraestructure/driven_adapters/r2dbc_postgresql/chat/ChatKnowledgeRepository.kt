package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.r2dbc.core.DatabaseClient
import org.springframework.stereotype.Repository
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Repositorio para gestionar el conocimiento del chat (RAG con vector search)
 */
@Repository
class ChatKnowledgeRepository(
    private val databaseClient: DatabaseClient
) {

    private val logger = LoggerFactory.getLogger(ChatKnowledgeRepository::class.java)

    /**
     * Guarda o actualiza una entrada de conocimiento con su embedding
     */
    fun saveKnowledge(
        externalId: String,
        snippet: String,
        embedding: List<Float>,
        source: String,
        metadata: Map<String, Any> = emptyMap()
    ): Mono<ChatKnowledge> {
        // Convertir lista de floats a formato vector de PostgreSQL
        val embeddingArray = embedding.joinToString(",", "[", "]")

        logger.info("Guardando knowledge: externalId=$externalId, source=$source")

        val metadataJson = ObjectMapper().writeValueAsString(metadata)
        // Usar UPSERT para actualizar si existe o insertar si no existe
        return databaseClient.sql("""
            INSERT INTO schmain.chat_knowledge
                (external_id, snippet, embedding, source, metadata, updated_at)
            VALUES
                (:externalId, :snippet, '$embeddingArray'::vector, :source, CAST(:metadata AS jsonb), :updatedAt)
            ON CONFLICT (external_id)
            DO UPDATE SET
                snippet = EXCLUDED.snippet,
                embedding = EXCLUDED.embedding,
                source = EXCLUDED.source,
                metadata = EXCLUDED.metadata,
                updated_at = EXCLUDED.updated_at
            RETURNING knowledge_id, external_id, snippet, source, metadata, updated_at
        """.trimIndent())
            .bind("externalId", externalId)
            .bind("snippet", snippet)
            .bind("source", source)
            .bind("metadata", metadataJson)
            .bind("updatedAt", LocalDateTime.now())
            .map { row ->
                ChatKnowledge(
                    knowledgeId = row.get("knowledge_id", java.lang.Long::class.java)?.toLong() ?: 0L,
                    externalId = row.get("external_id", String::class.java),
                    snippet = row.get("snippet", String::class.java) ?: "",
                    source = row.get("source", String::class.java),
                    updatedAt = row.get("updated_at", LocalDateTime::class.java) ?: LocalDateTime.now()
                )
            }
            .one()
            .doOnSuccess { logger.info("Knowledge guardado exitosamente: ${it.knowledgeId}") }
            .doOnError { error -> logger.error("Error guardando knowledge", error) }
    }

    /**
     * Busca las N entradas más similares usando similarity search con cosine distance
     * Usa el operador <=> de pgvector para calcular cosine distance
     */
    fun findSimilarKnowledge(
        queryEmbedding: List<Float>,
        limit: Int = 3,
        similarityThreshold: Double = 0.7
    ): Mono<List<ChatKnowledge>> {
        val embeddingArray = queryEmbedding.joinToString(",", "[", "]")

        logger.info("Buscando knowledge similar (limit=$limit, threshold=$similarityThreshold)")

        return databaseClient.sql("""
            SELECT
                knowledge_id,
                external_id,
                snippet,
                source,
                metadata,
                updated_at,
                1 - (embedding <=> '$embeddingArray'::vector) as similarity
            FROM schmain.chat_knowledge
            WHERE embedding IS NOT NULL
            ORDER BY embedding <=> '$embeddingArray'::vector
            LIMIT :limit
        """.trimIndent())
            .bind("limit", limit)
            .map { row ->
                val similarity = row.get("similarity", java.lang.Double::class.java)?.toDouble() ?: 0.0

                ChatKnowledge(
                    knowledgeId = row.get("knowledge_id", java.lang.Long::class.java)?.toLong() ?: 0L,
                    externalId = row.get("external_id", String::class.java),
                    snippet = row.get("snippet", String::class.java) ?: "",
                    source = row.get("source", String::class.java),
                    updatedAt = row.get("updated_at", LocalDateTime::class.java) ?: LocalDateTime.now(),
                    similarity = similarity
                )
            }
            .all()
            .collectList()
            .map { results ->
                // Filtrar por threshold de similitud
                results.filter { it.similarity >= similarityThreshold }
            }
            .doOnSuccess { results ->
                logger.info("Encontrados ${results.size} resultados similares")
                results.forEach {
                    logger.debug("  - ${it.externalId}: similarity=${String.format("%.3f", it.similarity)}")
                }
            }
            .doOnError { error -> logger.error("Error buscando knowledge similar", error) }
    }

    /**
     * Obtiene una entrada de conocimiento por su external_id
     */
    fun getByExternalId(externalId: String): Mono<ChatKnowledge> {
        return databaseClient.sql("""
            SELECT knowledge_id, external_id, snippet, source, metadata, updated_at
            FROM schmain.chat_knowledge
            WHERE external_id = :externalId
        """.trimIndent())
            .bind("externalId", externalId)
            .map { row ->
                ChatKnowledge(
                    knowledgeId = row.get("knowledge_id", java.lang.Long::class.java)?.toLong() ?: 0L,
                    externalId = row.get("external_id", String::class.java),
                    snippet = row.get("snippet", String::class.java) ?: "",
                    source = row.get("source", String::class.java),
                    updatedAt = row.get("updated_at", LocalDateTime::class.java) ?: LocalDateTime.now()
                )
            }
            .one()
    }

    /**
     * Cuenta el total de entradas en chat_knowledge
     */
    fun count(): Mono<Long> {
        return databaseClient.sql("""
            SELECT COUNT(*) as total FROM schmain.chat_knowledge
        """.trimIndent())
            .map { row ->
                row.get("total", java.lang.Long::class.java)?.toLong() ?: 0L
            }
            .one()
    }

    companion object {
        private val objectMapper = jacksonObjectMapper()
    }
}

/**
 * Modelo de dominio para chat_knowledge
 */
data class ChatKnowledge(
    val knowledgeId: Long,
    val externalId: String?,
    val snippet: String,
    val source: String?,
    val updatedAt: LocalDateTime,
    val similarity: Double = 0.0  // Solo se usa en búsquedas de similitud
)
