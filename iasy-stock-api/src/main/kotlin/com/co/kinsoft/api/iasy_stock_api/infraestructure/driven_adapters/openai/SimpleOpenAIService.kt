package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai

import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.IntentType
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.SQLExamplesProvider
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.UserIntent
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.cache.annotation.Cacheable
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.stereotype.Service
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.bodyToMono
import reactor.core.publisher.Mono
import java.time.Duration

@Service
class SimpleOpenAIService(
    @Value("\${openai.api-key}")
    private val apiKey: String,

    @Value("\${openai.model}")
    private val model: String,

    @Value("\${openai.max-tokens}")
    private val maxTokens: Int,

    @Value("\${openai.temperature}")
    private val temperature: Double,

) {

    private val logger = LoggerFactory.getLogger(SimpleOpenAIService::class.java)
    private val webClient = WebClient.builder()
        .baseUrl("https://api.openai.com")
        .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
        .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer $apiKey")
        .build()
    private val objectMapper: ObjectMapper = jacksonObjectMapper()

    fun generateResponse(prompt: String, contextData: Any?): Mono<String> {
        logger.info("Generando respuesta con OpenAI para prompt: ${prompt.take(100)}...")

        val systemPrompt = buildSystemPrompt(contextData)
        val fullPrompt = if (contextData != null) {
            "$systemPrompt\n\nDatos del contexto:\n$contextData\n\nPregunta del usuario: $prompt"
        } else {
            "$systemPrompt\n\nPregunta del usuario: $prompt"
        }

        val requestBodyMap = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf("role" to "system", "content" to systemPrompt),
                mapOf("role" to "user", "content" to fullPrompt)
            ),
            "max_tokens" to maxTokens,
            "temperature" to temperature
        )

        return webClient.post()
            .uri("/v1/chat/completions")
            .bodyValue(requestBodyMap)
            .retrieve()
            .bodyToMono<String>()
            .timeout(Duration.ofSeconds(60))
            .flatMap { responseBody ->
                logger.info("Respuesta recibida de OpenAI")
                val content = extractContentFromResponse(responseBody)
                if (content.isNotBlank()) {
                    logger.info("Respuesta generada exitosamente: ${content.take(100)}...")
                    Mono.just(content)
                } else {
                    Mono.just("No pude generar una respuesta válida.")
                }
            }
            .onErrorResume { error ->
                logger.error("Error generando respuesta con OpenAI", error)
                Mono.just("Lo siento, tuve un problema procesando tu consulta. ¿Podrías reformularla?")
            }
    }

    fun analyzeIntent(message: String, databaseSchema: String? = null): Mono<UserIntent> {
        logger.info("Analizando intención para mensaje: $message")

        val schemaSection = if (!databaseSchema.isNullOrBlank()) {
            """

            ESQUEMA DE LA BASE DE DATOS:
            $databaseSchema

            IMPORTANTE: Usa EXACTAMENTE la estructura de tablas y columnas mostradas arriba para generar el SQL.
            - La tabla 'sale' tiene la columna 'sale_date', NO la tabla 'saleitem'
            - Para filtrar ventas por fecha, debes hacer JOIN con la tabla 'sale'
            - Ejemplo correcto: "FROM schmain.saleitem si JOIN schmain.sale s ON si.sale_id = s.sale_id WHERE s.sale_date ..."
            """.trimIndent()
        } else {
            ""
        }

        // Obtener ejemplos SQL completos de SQLExamplesProvider
        val sqlExamplesSection = SQLExamplesProvider.getSQLExamples()

        val intentPrompt = """
            Analiza la siguiente pregunta del usuario y determina:
            1. El tipo de consulta (STOCK_QUERY, SALES_QUERY, PRODUCT_QUERY, GENERAL_QUERY)
            2. Si requiere consultar la base de datos
            3. Parámetros específicos mencionados (IDs de productos, fechas, etc.)
            4. La consulta SQL específica si es necesaria
            $schemaSection
            $sqlExamplesSection

            Pregunta: "$message"

            Responde en formato JSON:
            {
                "type": "STOCK_QUERY|SALES_QUERY|PRODUCT_QUERY|GENERAL_QUERY",
                "requiresDatabaseQuery": true/false,
                "parameters": {
                    "productId": null,
                    "categoryId": null,
                    "dateRange": null,
                    "limit": null
                },
                "query": "SELECT ... FROM ... WHERE ..."
            }

            Ejemplos de respuestas esperadas:
            - Para "¿Cuántos productos tengo en stock para el producto 5?":
              {"type": "STOCK_QUERY", "requiresDatabaseQuery": true, "parameters": {"productId": 5}, "query": "SELECT p.name, p.stock_quantity, p.stock_minimum, c.name as category_name FROM schmain.product p LEFT JOIN schmain.category c ON p.category_id = c.category_id WHERE p.product_id = 5"}

            - Para "¿Cuántos productos tengo en stock?":
              {"type": "STOCK_QUERY", "requiresDatabaseQuery": true, "parameters": {}, "query": "SELECT COUNT(*) as total_products, SUM(stock_quantity) as total_stock FROM schmain.product WHERE stock_quantity > 0"}

            - Para "¿Cuáles son mis productos más vendidos este mes?":
              {"type": "SALES_QUERY", "requiresDatabaseQuery": true, "parameters": {"limit": 10}, "query": "SELECT p.name, SUM(si.quantity) as total_sold, SUM(si.total_price) as total_revenue FROM schmain.product p LEFT JOIN schmain.saleitem si ON p.product_id = si.product_id LEFT JOIN schmain.sale s ON si.sale_id = s.sale_id WHERE DATE_TRUNC('month', s.sale_date) = DATE_TRUNC('month', CURRENT_DATE) GROUP BY p.product_id, p.name ORDER BY total_sold DESC LIMIT 10"}
        """.trimIndent()

        val requestBodyMap = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf("role" to "system", "content" to "Eres un experto en SQL y bases de datos relacionales para un sistema de inventarios. Tu tarea es analizar preguntas del usuario y generar consultas SQL precisas basándote en el esquema de BD y los ejemplos proporcionados."),
                mapOf("role" to "user", "content" to intentPrompt)
            ),
            "max_tokens" to 800,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("/v1/chat/completions")
            .bodyValue(requestBodyMap)
            .retrieve()
            .bodyToMono<String>()
            .timeout(Duration.ofSeconds(60))
            .flatMap { responseBody ->
                val content = extractContentFromResponse(responseBody)
                logger.info("Contenido de análisis de intención: $content")
                Mono.just(parseIntentResponse(content, message))
            }
            .onErrorResume { error ->
                logger.error("Error analizando intención con OpenAI, usando fallback local", error)
                // Usar fallback local inmediatamente cuando hay error de conexión
                Mono.just(parseIntentResponse("", message))
            }
    }

    private fun buildSystemPrompt(contextData: Any?): String {
        return """
            Eres un asistente inteligente para un sistema de gestión de inventarios llamado IasyStock.

            Tu función es ayudar a los usuarios a consultar información sobre:
            - Productos y stock disponible
            - Ventas y reportes
            - Categorías de productos
            - Clientes y proveedores
            - Alertas de inventario bajo
            - Productos por vencer

            Responde de manera clara, concisa y útil. Si tienes datos específicos, úsalos para dar respuestas precisas.
            Si no tienes datos suficientes, sugiere qué información adicional podría ser útil.

            Responde siempre en español de manera amigable y profesional.
        """.trimIndent()
    }

    private fun extractContentFromResponse(responseBody: String): String {
        return try {
            // Intentar parsear como JSON usando ObjectMapper
            val jsonNode = objectMapper.readTree(responseBody)
            val choices = jsonNode.get("choices")

            if (choices != null && choices.isArray && choices.size() > 0) {
                val firstChoice = choices.get(0)
                val message = firstChoice.get("message")

                if (message != null) {
                    val content = message.get("content")
                    if (content != null) {
                        val extractedContent = content.asText()
                        logger.info("Contenido extraído exitosamente: ${extractedContent.take(100)}...")
                        return extractedContent
                    }
                }
            }

            // Fallback: método anterior si el parsing JSON falla
            logger.warn("Fallback a método de extracción manual")
            val contentStart = responseBody.indexOf("\"content\":\"") + 10
            val contentEnd = responseBody.indexOf("\"", contentStart)
            if (contentStart in 10..<contentEnd) {
                responseBody.substring(contentStart, contentEnd)
                    .replace("\\n", "\n")
                    .replace("\\\"", "\"")
            } else {
                logger.error("No se pudo extraer contenido de la respuesta")
                ""
            }
        } catch (e: Exception) {
            logger.error("Error parseando respuesta JSON: ${e.message}")
            logger.error("Respuesta completa: $responseBody")
            ""
        }
    }

    private fun parseIntentResponse(response: String, originalMessage: String): UserIntent {
        return try {
            // Intentar parsear como JSON primero
            if (response.contains("{") && response.contains("}")) {
                val jsonStart = response.indexOf("{")
                val jsonEnd = response.lastIndexOf("}") + 1
                val jsonString = response.substring(jsonStart, jsonEnd)

                try {
                    val jsonNode = objectMapper.readTree(jsonString)
                    val type = jsonNode.get("type")?.asText() ?: "GENERAL_QUERY"
                    val requiresDatabaseQuery = jsonNode.get("requiresDatabaseQuery")?.asBoolean() ?: false
                    val query = jsonNode.get("query")?.asText()
                    val parameters = jsonNode.get("parameters")?.let { params ->
                        params.fieldNames().asSequence().associate { key ->
                            key to (params.get(key)?.asText() ?: "")
                        }
                    } ?: emptyMap()

                    return UserIntent(
                        type = when (type.uppercase()) {
                            "STOCK_QUERY" -> IntentType.STOCK_QUERY
                            "SALES_QUERY" -> IntentType.SALES_QUERY
                            "PRODUCT_QUERY" -> IntentType.PRODUCT_QUERY
                            else -> IntentType.GENERAL_QUERY
                        },
                        query = query,
                        requiresDatabaseQuery = requiresDatabaseQuery,
                        parameters = parameters
                    )
                } catch (e: Exception) {
                    logger.warn("Error parseando JSON de intención, usando fallback: $e")
                }
            }

            // Fallback: análisis inteligente basado en palabras clave y patrones
            val lowerMessage = originalMessage.lowercase()
            logger.info("Usando análisis local para: '$originalMessage'")

            when {
                // Consultas de stock específicas - PRIORIDAD ALTA
                (lowerMessage.contains("stock") || lowerMessage.contains("inventario") || lowerMessage.contains("cantidad")) && extractProductId(originalMessage) != null -> {
                    val productId = extractProductId(originalMessage)!!
                    logger.info("Detectada consulta de stock específica para producto ID: $productId")
                    val query = """
                        SELECT 
                            p.name,
                            p.stock_quantity,
                            p.stock_minimum,
                            p.price,
                            c.name as category_name,
                            CASE 
                                WHEN p.stock_quantity <= p.stock_minimum THEN 'Stock bajo'
                                WHEN p.stock_quantity = 0 THEN 'Sin stock'
                                ELSE 'Stock disponible'
                            END as stock_status
                        FROM schmain.Product p
                        LEFT JOIN schmain.Category c ON p.category_id = c.category_id
                        WHERE p.product_id = $productId
                    """.trimIndent()

                    UserIntent(
                        IntentType.STOCK_QUERY,
                        query = query,
                        requiresDatabaseQuery = true,
                        parameters = mapOf("productId" to productId.toString())
                    )
                }

                // Consultas generales de stock
                lowerMessage.contains("stock") || lowerMessage.contains("inventario") || lowerMessage.contains("cantidad") -> {
                    logger.info("Detectada consulta general de stock")
                    val query = """
                        SELECT 
                            COUNT(*) as total_products,
                            SUM(stock_quantity) as total_stock,
                            COUNT(CASE WHEN stock_quantity <= stock_minimum THEN 1 END) as low_stock_products,
                            COUNT(CASE WHEN stock_quantity = 0 THEN 1 END) as out_of_stock_products,
                            COUNT(CASE WHEN expiration_date <= CURRENT_DATE + INTERVAL '30 days' THEN 1 END) as expiring_products
                        FROM schmain.Product
                    """.trimIndent()

                    UserIntent(
                        IntentType.STOCK_QUERY,
                        query = query,
                        requiresDatabaseQuery = true
                    )
                }

                // Consultas de productos más vendidos
                lowerMessage.contains("vendido") || (lowerMessage.contains("venta") && lowerMessage.contains("producto")) -> {
                    logger.info("Detectada consulta de productos más vendidos")
                    val query = """
                        SELECT 
                            p.name,
                            COALESCE(SUM(si.quantity), 0) as total_sold,
                            COALESCE(SUM(si.total_price), 0) as total_revenue,
                            c.name as category_name
                        FROM schmain.Product p
                        LEFT JOIN schmain.SaleItem si ON p.product_id = si.product_id
                        LEFT JOIN schmain.Category c ON p.category_id = c.category_id
                        GROUP BY p.product_id, p.name, c.name
                        ORDER BY total_sold DESC
                        LIMIT 10
                    """.trimIndent()

                    UserIntent(
                        IntentType.SALES_QUERY,
                        query = query,
                        requiresDatabaseQuery = true
                    )
                }

                // Consultas de ventas recientes / listado de ventas
                (lowerMessage.contains("venta") || lowerMessage.contains("ventas")) &&
                (lowerMessage.contains("reciente") || lowerMessage.contains("última") ||
                 lowerMessage.contains("ultima") || lowerMessage.contains("ultimas") ||
                 lowerMessage.contains("últimas") || lowerMessage.contains("listado") ||
                 lowerMessage.contains("lista") || lowerMessage.contains("dame")) -> {
                    logger.info("Detectada consulta de ventas recientes/listado")
                    val query = """
                        SELECT 
                            s.sale_id,
                            s.total_amount,
                            s.sale_date,
                            s.pay_method,
                            p.name as person_name
                        FROM schmain.Sale s
                        LEFT JOIN schmain.Person p ON s.person_id = p.person_id
                        ORDER BY s.sale_date DESC
                        LIMIT 10
                    """.trimIndent()

                    UserIntent(
                        IntentType.SALES_QUERY,
                        query = query,
                        requiresDatabaseQuery = true
                    )
                }

                // Consultas específicas de producto
                lowerMessage.contains("producto") && extractProductId(originalMessage) != null -> {
                    val productId = extractProductId(originalMessage)!!
                    logger.info("Detectada consulta específica de producto ID: $productId")
                    val query = """
                        SELECT 
                            p.*,
                            c.name as category_name
                        FROM schmain.Product p
                        LEFT JOIN schmain.Category c ON p.category_id = c.category_id
                        WHERE p.product_id = $productId
                    """.trimIndent()

                    UserIntent(
                        IntentType.PRODUCT_QUERY,
                        query = query,
                        requiresDatabaseQuery = true,
                        parameters = mapOf("productId" to productId.toString())
                    )
                }

                // Consultas generales de productos
                lowerMessage.contains("producto") -> {
                    logger.info("Detectada consulta general de productos")
                    val query = """
                        SELECT 
                            p.*,
                            c.name as category_name
                        FROM schmain.Product p
                        LEFT JOIN schmain.Category c ON p.category_id = c.category_id
                        ORDER BY p.name
                    """.trimIndent()

                    UserIntent(
                        IntentType.PRODUCT_QUERY,
                        query = query,
                        requiresDatabaseQuery = true
                    )
                }

                // Consultas de stock bajo
                lowerMessage.contains("bajo") || lowerMessage.contains("agotar") -> {
                    logger.info("Detectada consulta de stock bajo")
                    val query = """
                        SELECT 
                            p.name,
                            p.stock_quantity,
                            p.stock_minimum,
                            c.name as category_name
                        FROM schmain.Product p
                        LEFT JOIN schmain.Category c ON p.category_id = c.category_id
                        WHERE p.stock_quantity <= p.stock_minimum
                        ORDER BY p.stock_quantity ASC
                    """.trimIndent()

                    UserIntent(
                        IntentType.STOCK_QUERY,
                        query = query,
                        requiresDatabaseQuery = true
                    )
                }

                else -> {
                    logger.info("No se detectó patrón específico, usando consulta general")
                    UserIntent(IntentType.GENERAL_QUERY, requiresDatabaseQuery = false)
                }
            }
        } catch (e: Exception) {
            logger.error("Error parseando respuesta de intención", e)
            UserIntent(IntentType.GENERAL_QUERY, requiresDatabaseQuery = false)
        }
    }

    private fun extractProductId(message: String): Int? {
        // Buscar patrones como "producto 5", "producto #5", "ID 5", etc.
        val patterns = listOf(
            Regex("producto\\s+(?:#)?(\\d+)", RegexOption.IGNORE_CASE),
            Regex("id\\s+(?:del\\s+)?producto\\s+(?:#)?(\\d+)", RegexOption.IGNORE_CASE),
            Regex("producto\\s+con\\s+id\\s+(?:#)?(\\d+)", RegexOption.IGNORE_CASE),
            Regex("producto\\s+numero\\s+(?:#)?(\\d+)", RegexOption.IGNORE_CASE),
            Regex("producto\\s+(?:con\\s+)?(?:el\\s+)?(?:numero\\s+)?(?:#)?(\\d+)", RegexOption.IGNORE_CASE),
            Regex("(?:el\\s+)?producto\\s+(?:#)?(\\d+)", RegexOption.IGNORE_CASE),
            Regex("(?:para\\s+el\\s+)?producto\\s+(?:#)?(\\d+)", RegexOption.IGNORE_CASE)
        )

        for (pattern in patterns) {
            val match = pattern.find(message)
            if (match != null) {
                val productId = match.groupValues[1].toIntOrNull()
                logger.info("Extraído ID de producto: $productId del patrón: ${match.value}")
                return productId
            }
        }

        logger.info("No se encontró ID de producto en el mensaje: '$message'")
        return null
    }

    /**
     * Genera un embedding vectorial para un texto usando OpenAI embeddings API
     * Modelo: text-embedding-3-small (1536 dimensiones)
     *
     * OPTIMIZADO: Usa caché Caffeine con TTL de 6 horas
     * La key del caché es el hash del texto para evitar duplicados
     */
    @Cacheable(value = ["embeddings"], key = "#text.hashCode()")
    fun generateEmbedding(text: String): Mono<List<Float>> {
        logger.info("Generando embedding para texto (sin caché): ${text.take(100)}...")

        val requestBodyMap = mapOf(
            "model" to "text-embedding-3-small",
            "input" to text
        )

        return webClient.post()
            .uri("/v1/embeddings")
            .bodyValue(requestBodyMap)
            .retrieve()
            .bodyToMono<String>()
            .timeout(Duration.ofSeconds(60))
            .flatMap { responseBody ->
                try {
                    val jsonNode = objectMapper.readTree(responseBody)
                    val embeddingData = jsonNode.get("data")
                        ?.get(0)
                        ?.get("embedding")

                    if (embeddingData != null && embeddingData.isArray) {
                        val embedding = mutableListOf<Float>()
                        embeddingData.forEach { node ->
                            embedding.add(node.asDouble().toFloat())
                        }
                        logger.info("Embedding generado exitosamente: ${embedding.size} dimensiones")
                        Mono.just(embedding as List<Float>)
                    } else {
                        logger.error("No se pudo extraer embedding de la respuesta")
                        Mono.just(emptyList())
                    }
                } catch (e: Exception) {
                    logger.error("Error parseando embedding", e)
                    Mono.just(emptyList())
                }
            }
            .onErrorResume { error ->
                logger.error("Error generando embedding con OpenAI", error)
                Mono.just(emptyList())
            }
    }

    /**
     * Corrige un SQL que falló basándose en el feedback del error
     */
    fun correctSQL(
        failedQuery: String,
        errorFeedback: String,
        databaseSchema: String
    ): Mono<String> {
        logger.info("Intentando corregir SQL que falló")

        val correctionPrompt = """
            El siguiente SQL falló al ejecutarse:

            SQL FALLIDO:
            $failedQuery

            $errorFeedback

            ESQUEMA DE LA BASE DE DATOS:
            $databaseSchema

            INSTRUCCIONES:
            1. Analiza el error cuidadosamente
            2. Corrige el SQL según el error y el esquema proporcionado
            3. Verifica que uses el schema 'schmain' (ej: schmain.product)
            4. Asegúrate que todas las columnas existan en el esquema
            5. Para agregaciones, incluye todas las columnas no agregadas en GROUP BY
            6. Para JOINs, verifica las condiciones ON
            7. Responde SOLO con el SQL corregido, sin explicaciones adicionales

            SQL CORREGIDO:
        """.trimIndent()

        val requestBodyMap = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf("role" to "system", "content" to "Eres un experto en SQL y PostgreSQL que corrige queries problemáticos."),
                mapOf("role" to "user", "content" to correctionPrompt)
            ),
            "max_tokens" to 500,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("/v1/chat/completions")
            .bodyValue(requestBodyMap)
            .retrieve()
            .bodyToMono<String>()
            .timeout(Duration.ofSeconds(60))
            .flatMap { responseBody ->
                val correctedSQL = extractContentFromResponse(responseBody)
                // CORRECCIÓN: Limpiar backticks markdown y otros formatos que OpenAI pueda devolver
                val cleanedSQL = cleanSQLResponse(correctedSQL)
                logger.info("SQL corregido generado: ${cleanedSQL.take(100)}...")
                Mono.just(cleanedSQL)
            }
            .onErrorResume { error ->
                logger.error("Error en corrección de SQL", error)
                Mono.just(failedQuery) // Retornar el original si falla
            }
    }

    /**
     * Limpia la respuesta de SQL removiendo backticks markdown y otros formatos
     */
    private fun cleanSQLResponse(sql: String): String {
        var cleaned = sql.trim()

        // Remover bloques de código markdown (```sql ... ``` o ``` ... ```)
        cleaned = cleaned.replace(Regex("```sql\\s*"), "")
        cleaned = cleaned.replace(Regex("```\\s*"), "")

        // Remover comillas simples o dobles al inicio y fin si existen
        cleaned = cleaned.trim('"', '\'', '`')

        return cleaned.trim()
    }
}