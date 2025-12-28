package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.SimpleOpenAIService
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatKnowledge
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatKnowledgeRepository
import org.slf4j.LoggerFactory
import reactor.core.publisher.Mono
import java.security.MessageDigest

/**
 * Servicio para gestionar el conocimiento del chat usando RAG (Retrieval-Augmented Generation)
 */
class ChatKnowledgeUseCase(
    private val chatKnowledgeRepository: ChatKnowledgeRepository,
    private val openAIService: SimpleOpenAIService
) {

    private val logger = LoggerFactory.getLogger(ChatKnowledgeUseCase::class.java)

    /**
     * Guarda una consulta exitosa en la base de conocimiento
     * @param userQuestion Pregunta original del usuario
     * @param sqlQuery SQL generado que fue exitoso
     * @param metadata Metadatos adicionales (ej: userId, timestamp, etc.)
     */
    fun saveSuccessfulQuery(
        userQuestion: String,
        sqlQuery: String,
        metadata: Map<String, Any> = emptyMap()
    ): Mono<ChatKnowledge> {
        logger.info("Guardando consulta exitosa en knowledge base")

        // Combinar pregunta y SQL para el snippet
        val snippet = """
            Pregunta: $userQuestion
            SQL: $sqlQuery
        """.trimIndent()

        // Generar un external_id único basado en la pregunta (hash MD5)
        val externalId = generateExternalId(userQuestion)

        // Generar embedding del snippet
        return openAIService.generateEmbedding(snippet)
            .flatMap { embedding ->
                if (embedding.isEmpty()) {
                    logger.warn("No se pudo generar embedding, no se guardará en knowledge base")
                    Mono.empty()
                } else {
                    val enrichedMetadata = metadata.toMutableMap()
                    enrichedMetadata["user_question"] = userQuestion
                    enrichedMetadata["sql_query"] = sqlQuery

                    chatKnowledgeRepository.saveKnowledge(
                        externalId = externalId,
                        snippet = snippet,
                        embedding = embedding,
                        source = "chat_assistant",
                        metadata = enrichedMetadata
                    )
                }
            }
            .doOnSuccess { logger.info("Consulta guardada exitosamente en knowledge base") }
            .doOnError { error -> logger.error("Error guardando consulta en knowledge base", error) }
            .onErrorResume { Mono.empty() } // No fallar si no se puede guardar
    }

    /**
     * Busca consultas similares en la base de conocimiento
     * @param userQuestion Pregunta del usuario
     * @param limit Número máximo de resultados
     * @param similarityThreshold Umbral de similitud (0.0-1.0)
     * @return Lista de queries similares ordenadas por similitud descendente
     */
    fun findSimilarQueries(
        userQuestion: String,
        limit: Int = 3,
        similarityThreshold: Double = 0.7
    ): Mono<List<SimilarQuery>> {
        logger.info("Buscando queries similares a: '${userQuestion.take(50)}...'")

        return openAIService.generateEmbedding(userQuestion)
            .flatMap { embedding ->
                if (embedding.isEmpty()) {
                    logger.warn("No se pudo generar embedding para búsqueda")
                    Mono.just(emptyList())
                } else {
                    chatKnowledgeRepository.findSimilarKnowledge(
                        queryEmbedding = embedding,
                        limit = limit,
                        similarityThreshold = similarityThreshold
                    )
                }
            }
            .map { knowledgeList ->
                // Convertir ChatKnowledge a SimilarQuery parseando el snippet
                knowledgeList.map { knowledge ->
                    parseSimilarQuery(knowledge)
                }
            }
            .doOnSuccess { results ->
                logger.info("Encontradas ${results.size} consultas similares")
                results.forEach {
                    logger.debug(
                        "  - Similarity: ${
                            String.format(
                                "%.3f",
                                it.similarity
                            )
                        } | Q: ${it.userQuestion.take(50)}"
                    )
                }
            }
            .doOnError { error -> logger.error("Error buscando queries similares", error) }
            .onErrorReturn(emptyList())
    }

    /**
     * Formatea las consultas similares como ejemplos para el prompt
     */
    fun formatSimilarQueriesAsExamples(similarQueries: List<SimilarQuery>): String {
        if (similarQueries.isEmpty()) {
            return ""
        }

        return """

        EJEMPLOS DE CONSULTAS SIMILARES EXITOSAS (basado en tu historial):

        ${
            similarQueries.mapIndexed { index, query ->
                """
            ${index + 1}. Pregunta similar (similitud: ${String.format("%.1f%%", query.similarity * 100)}):
               "${query.userQuestion}"

               SQL usado:
               ${query.sqlQuery}
            """.trimIndent()
            }.joinToString("\n\n")
        }

        IMPORTANTE: Usa estos ejemplos como referencia, pero ajusta el SQL según la pregunta actual del usuario.
        """.trimIndent()
    }

    /**
     * Genera un ID único basado en la pregunta del usuario (hash MD5)
     */
    private fun generateExternalId(userQuestion: String): String {
        val normalized = userQuestion.lowercase().trim()
        val md5 = MessageDigest.getInstance("MD5")
        val hashBytes = md5.digest(normalized.toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * Parsea el snippet de ChatKnowledge para extraer pregunta y SQL
     */
    private fun parseSimilarQuery(knowledge: ChatKnowledge): SimilarQuery {
        val lines = knowledge.snippet.lines()
        var userQuestion = ""
        var sqlQuery = ""

        var readingSQL = false
        val sqlLines = mutableListOf<String>()

        for (line in lines) {
            when {
                line.startsWith("Pregunta:") -> {
                    userQuestion = line.removePrefix("Pregunta:").trim()
                }

                line.startsWith("SQL:") -> {
                    sqlQuery = line.removePrefix("SQL:").trim()
                    readingSQL = true
                }

                readingSQL -> {
                    sqlLines.add(line)
                }
            }
        }

        // Si el SQL está en múltiples líneas, reconstruirlo
        if (sqlLines.isNotEmpty()) {
            sqlQuery = sqlLines.joinToString("\n")
        }

        return SimilarQuery(
            userQuestion = userQuestion,
            sqlQuery = sqlQuery,
            similarity = knowledge.similarity
        )
    }
}

/**
 * Representa una consulta similar encontrada en la base de conocimiento
 */
data class SimilarQuery(
    val userQuestion: String,
    val sqlQuery: String,
    val similarity: Double
)
