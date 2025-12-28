package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

import com.co.kinsoft.api.iasy_stock_api.domain.model.chat.ChatRequest
import com.co.kinsoft.api.iasy_stock_api.domain.model.chat.ChatResponse
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.SimpleOpenAIService
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatSession
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatSessionRepository
import org.slf4j.LoggerFactory
import reactor.core.publisher.Mono

class ChatUseCase(
    private val openAIService: SimpleOpenAIService,
    private val databaseQueryUseCase: DatabaseQueryUseCase,
    private val promptBuilderUseCase: PromptBuilderUseCase,
    private val databaseSchemaUseCase: DatabaseSchemaUseCase,
    private val chatSessionRepository: ChatSessionRepository,
    private val chatKnowledgeUseCase: ChatKnowledgeUseCase
) {

    private val logger = LoggerFactory.getLogger(ChatUseCase::class.java)

    fun processMessage(request: ChatRequest): Mono<ChatResponse> {
        return Mono.fromCallable {
            logger.info("Procesando mensaje del usuario ${request.userId}: ${request.message}")
        }
            .then(
                // 1. Obtener o crear sesión
                getOrCreateSession(request)
            )
            .flatMap { session ->
                // 2. Guardar mensaje del usuario en la sesión
                chatSessionRepository.saveMessage(session.sessionId, "user", request.message)
                    .then(Mono.just(session))
            }
            .flatMap { session ->
                // 3. Recuperar historial de mensajes de la sesión
                chatSessionRepository.getSessionMessages(session.sessionId, 20)
                    .flatMap { history ->
                        // 4 y 5. OPTIMIZACIÓN: Ejecutar en paralelo búsqueda RAG y análisis de intención
                        // Son operaciones independientes que se pueden ejecutar concurrentemente
                        Mono.zip(
                            chatKnowledgeUseCase.findSimilarQueries(request.message, limit = 3, similarityThreshold = 0.7),
                            analyzeUserIntent(request.message)
                        ).flatMap { tuple ->
                            val similarQueries = tuple.t1
                            val intent = tuple.t2
                            logger.info("Encontradas ${similarQueries.size} consultas similares para RAG")
                            logger.info("Intención detectada: ${intent.type}, requiere BD: ${intent.requiresDatabaseQuery}")

                            // 6. Obtener datos de BD si es necesario (con validación y auto-corrección)
                            val dataQuery =
                                if (intent.requiresDatabaseQuery && !intent.query.isNullOrBlank()) {
                                    logger.info("Ejecutando consulta con validación: ${intent.query}")
                                    executeQueryWithAutoCorrection(intent.query, request.userId, session.sessionId.toString())
                                        .flatMap { data ->
                                            // 7. Guardar consulta exitosa en knowledge base si retornó datos
                                            // Verificar que no sea un mensaje de error (case-insensitive)
                                            val isError = data.contains("ERROR", ignoreCase = true) ||
                                                         data.contains("Lo siento, no pude ejecutar", ignoreCase = true)
                                            if (data.isNotBlank() && !isError) {
                                                chatKnowledgeUseCase.saveSuccessfulQuery(
                                                    userQuestion = request.message,
                                                    sqlQuery = intent.query,
                                                    metadata = mapOf(
                                                        "userId" to request.userId,
                                                        "intentType" to intent.type.toString()
                                                    )
                                                ).thenReturn(data)
                                                    .onErrorResume { Mono.just(data) } // No fallar si no se puede guardar
                                            } else {
                                                Mono.just(data)
                                            }
                                        }
                                } else {
                                    Mono.just("")
                                }

                            // 8. Construir prompt con historial, datos y consultas similares (RAG)
                            dataQuery.flatMap { data ->
                                val actualData = if (data.isBlank()) null else data
                                promptBuilderUseCase.buildPrompt(
                                    request.message,
                                    intent,
                                    actualData,
                                    history,
                                    similarQueries
                                )
                                    .flatMap { prompt ->
                                        // 9. Generar respuesta con OpenAI
                                        openAIService.generateResponse(prompt, actualData)
                                            .map { response ->
                                                Triple(session, response, actualData)
                                            }
                                    }
                            }
                        }
                    }
            }
            .flatMap { (session, response, _) ->
                // 8. Guardar respuesta del asistente en la sesión
                chatSessionRepository.saveMessage(session.sessionId, "assistant", response)
                    .then(chatSessionRepository.updateLastInteraction(session.sessionId))
                    .thenReturn(
                        ChatResponse(
                            message = response,
                            sessionId = session.sessionId.toString(),
                            data = null,
                            suggestions = generateSuggestions(request.message)
                        )
                    )
            }
            .onErrorResume { error ->
                logger.error("Error procesando mensaje del chat", error)
                // Intentar recuperar sessionId del request para mantener contexto incluso en error
                val sessionIdStr = request.sessionId
                Mono.just(
                    ChatResponse(
                        message = "Lo siento, tuve un problema procesando tu consulta. ¿Podrías reformularla?",
                        sessionId = sessionIdStr,
                        data = null,
                        suggestions = listOf(
                            "¿Cuántos productos tengo en stock?",
                            "¿Cuáles son mis productos más vendidos?",
                            "¿Qué productos están por vencer?"
                        )
                    )
                )
            }
    }

    /**
     * Obtiene una sesión existente o crea una nueva
     */
    private fun getOrCreateSession(request: ChatRequest): Mono<ChatSession> {
        return if (request.sessionId != null) {
            // Intentar recuperar sesión existente
            try {
                val sessionUUID = java.util.UUID.fromString(request.sessionId)
                chatSessionRepository.getSessionById(sessionUUID)
                    .onErrorResume { error ->
                        logger.warn("No se pudo recuperar sesión ${request.sessionId}, creando nueva: ${error.message}")
                        chatSessionRepository.createSession(request.userId)
                    }
            } catch (e: IllegalArgumentException) {
                logger.warn("SessionId inválido: ${request.sessionId}, creando nueva sesión")
                chatSessionRepository.createSession(request.userId)
            }
        } else {
            // Crear nueva sesión
            chatSessionRepository.createSession(request.userId)
        }
    }

    fun getChatHistory(userId: Long): Mono<List<ChatResponse>> {
        // TODO: Implementar historial de chat
        return Mono.just(emptyList())
    }

    fun testDatabaseConnection(): Mono<String> {
        return databaseQueryUseCase.executeQuery("SELECT COUNT(*) as total FROM schmain.Product")
            .onErrorResume { error ->
                logger.error("Error en test de conexión a BD", error)
                Mono.just("Error de conexión: ${error.message}")
            }
    }

    private fun analyzeUserIntent(message: String): Mono<UserIntent> {
        return databaseSchemaUseCase.getCompleteSchema()
            .flatMap { schema ->
                openAIService.analyzeIntent(message, schema)
            }
            .onErrorResume { error ->
                logger.warn("Error obteniendo esquema, analizando intención sin esquema: ${error.message}")
                openAIService.analyzeIntent(message)
            }
    }

    /**
     * Ejecuta un query con validación y auto-corrección en caso de error
     * Máximo 2 intentos: query original + 1 retry con corrección
     */
    private fun executeQueryWithAutoCorrection(
        query: String,
        userId: Long,
        sessionId: String,
        maxRetries: Int = 1
    ): Mono<String> {
        return databaseQueryUseCase.executeQueryWithValidation(query, userId, sessionId)
            .flatMap { result ->
                if (result.success) {
                    // Query ejecutado exitosamente
                    logger.info("Query ejecutado exitosamente")
                    Mono.just(result.data ?: "")
                } else {
                    // Query falló, intentar auto-corrección
                    if (maxRetries > 0) {
                        logger.warn("Query falló con error: ${result.error}. Intentando auto-corrección (retries restantes: $maxRetries)...")

                        // Construir feedback de error para OpenAI
                        val errorFeedback = """
                            ERROR DETECTADO:
                            ${result.error}

                            TIPO DE ERROR:
                            ${result.validationResult?.errorType ?: "UNKNOWN"}

                            SUGERENCIA DE CORRECCIÓN:
                            ${result.validationResult?.suggestion ?: "Verifica la sintaxis SQL"}

                            INSTRUCCIONES:
                            1. Analiza el error y la sugerencia proporcionada
                            2. Corrige el SQL siguiendo las reglas establecidas
                            3. Asegúrate de usar el schema 'schmain' (ej: schmain.product)
                            4. Verifica que todas las columnas y tablas existan según el esquema proporcionado
                            5. Si usas agregaciones, incluye todas las columnas no agregadas en GROUP BY
                            6. Para JOINs, verifica que las columnas de unión existan en ambas tablas
                        """.trimIndent()

                        // Obtener schema completo y corregir SQL
                        databaseSchemaUseCase.getCompleteSchema()
                            .flatMap { schema ->
                                logger.info("Enviando SQL a OpenAI para corrección...")
                                openAIService.correctSQL(query, errorFeedback, schema)
                            }
                            .flatMap { correctedSQL ->
                                logger.info("SQL corregido recibido de OpenAI: ${correctedSQL.take(100)}...")
                                // Retry con el SQL corregido (sin más retries para evitar loops infinitos)
                                executeQueryWithAutoCorrection(correctedSQL, userId, sessionId, maxRetries - 1)
                            }
                    } else {
                        // No más retries, retornar mensaje de error
                        logger.error("Query falló después de intentos de auto-corrección: ${result.error}")
                        Mono.just(
                            """
                            Lo siento, no pude ejecutar la consulta correctamente.

                            Error: ${result.error}
                            Sugerencia: ${result.validationResult?.suggestion ?: "Por favor, reformula tu pregunta con más detalles"}
                            """.trimIndent()
                        )
                    }
                }
            }
    }

    private fun generateSuggestions(message: String): List<String> {
        return when {
            message.contains("stock", ignoreCase = true) -> listOf(
                "¿Cuántos productos tengo en stock?",
                "¿Qué productos están por agotarse?",
                "¿Cuál es mi inventario total?"
            )

            message.contains("venta", ignoreCase = true) -> listOf(
                "¿Cuáles son mis productos más vendidos?",
                "¿Cuánto vendí este mes?",
                "¿Cuál es mi mejor cliente?"
            )

            message.contains("producto", ignoreCase = true) -> listOf(
                "¿Qué productos tengo disponibles?",
                "¿Cuáles productos están por vencer?",
                "¿Qué categorías de productos tengo?"
            )

            else -> listOf(
                "¿Cuántos productos tengo en stock?",
                "¿Cuáles son mis productos más vendidos?",
                "¿Qué productos están por vencer?"
            )
        }
    }
}

data class UserIntent(
    val type: IntentType,
    val query: String? = null,
    val requiresDatabaseQuery: Boolean = false,
    var parameters: Map<String, String> = emptyMap()
)

enum class IntentType {
    STOCK_QUERY,
    SALES_QUERY,
    PRODUCT_QUERY,
    GENERAL_QUERY
} 