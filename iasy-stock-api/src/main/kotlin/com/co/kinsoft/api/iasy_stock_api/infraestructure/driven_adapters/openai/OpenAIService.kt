package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai

import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ImageEmbeddingResult
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.annotation.JsonDeserialize
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.WebClientRequestException
import reactor.core.publisher.Mono
import reactor.util.retry.Retry
import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.math.BigDecimal
import java.time.Duration
import java.util.*
import javax.imageio.ImageIO

@Service
class OpenAIService(
    private val webClient: WebClient,
    private val objectMapper: ObjectMapper
) {

    private val logger: Logger = LoggerFactory.getLogger(OpenAIService::class.java)

    @Value("\${openai.api-key}")
    private lateinit var apiKey: String

    @Value("\${openai.model:gpt-4-vision-preview}")
    private lateinit var model: String

    @Value("\${openai.embedding-model:text-embedding-3-small}")
    private lateinit var embeddingModel: String

    companion object {
        private const val OPENAI_API_URL = "https://api.openai.com/v1"
        private const val EMBEDDING_DIMENSIONS = 1536

        // Configuración de reintentos
        private const val MAX_RETRY_ATTEMPTS = 3L
        private val RETRY_MIN_BACKOFF = Duration.ofSeconds(1)
        private val RETRY_MAX_BACKOFF = Duration.ofSeconds(10)
    }

    /**
     * Crea una política de reintentos para llamadas a OpenAI
     * Reintenta en caso de Connection reset, timeouts y errores de red
     */
    private fun createRetryPolicy(): Retry {
        return Retry.backoff(MAX_RETRY_ATTEMPTS, RETRY_MIN_BACKOFF)
            .maxBackoff(RETRY_MAX_BACKOFF)
            .filter { throwable ->
                // Reintentar solo en errores de conexión/red
                when (throwable) {
                    is WebClientRequestException -> {
                        val message = throwable.message ?: ""
                        message.contains("Connection reset", ignoreCase = true) ||
                        message.contains("Connection refused", ignoreCase = true) ||
                        message.contains("Timeout", ignoreCase = true) ||
                        message.contains("Read timed out", ignoreCase = true)
                    }
                    is java.net.SocketException -> true
                    is java.io.IOException -> true
                    else -> false
                }
            }
            .doBeforeRetry { signal ->
                logger.warn(
                    "Reintentando llamada a OpenAI (intento ${signal.totalRetries() + 1}/$MAX_RETRY_ATTEMPTS) " +
                    "debido a: ${signal.failure().message}"
                )
            }
            .onRetryExhaustedThrow { _, signal ->
                logger.error("Se agotaron los reintentos para OpenAI después de ${signal.totalRetries()} intentos")
                signal.failure()
            }
    }

    /**
     * Genera embedding vectorial para una imagen usando OpenAI
     * Para imágenes, usamos GPT-4 Vision para generar una descripción y luego
     * convertimos esa descripción en embedding usando el modelo de texto
     */
    fun generateImageEmbedding(imageBytes: ByteArray): Mono<ImageEmbeddingResult> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        // Log para debug
        logger.info("Generando embedding - Tamaño imagen: ${imageBytes.size} bytes, Base64 length: ${base64Image.length}")

        // Primero, generamos una descripción de la imagen usando GPT-4 Vision
        val visionRequest = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to "Describe detalladamente esta imagen de producto en una sola frase. Incluye el tipo de producto, marca, colores principales y características distintivas."
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/png;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 150
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(visionRequest)
            .retrieve()
            .onStatus({ it.is4xxClientError || it.is5xxServerError }) { response ->
                response.bodyToMono(String::class.java)
                    .defaultIfEmpty("No error body")
                    .flatMap { errorBody ->
                        logger.error("Error de OpenAI - Status: ${response.statusCode()}, Body: $errorBody")
                        Mono.error(RuntimeException("OpenAI Error: ${response.statusCode()} - $errorBody"))
                    }
            }
            .bodyToMono(OpenAIVisionResponse::class.java)
            .retryWhen(createRetryPolicy())
            .flatMap { visionResponse ->
                val description = visionResponse.choices.firstOrNull()?.message?.content
                    ?: return@flatMap Mono.error(RuntimeException("No se pudo generar la descripción de la imagen"))

                // Ahora generamos el embedding de la descripción usando el modelo de texto
                val embeddingRequest = mapOf(
                    "model" to embeddingModel,
                    "input" to description
                )

                webClient.post()
                    .uri("$OPENAI_API_URL/embeddings")
                    .header("Authorization", "Bearer $apiKey")
                    .header("Content-Type", "application/json")
                    .bodyValue(embeddingRequest)
                    .retrieve()
                    .bodyToMono(OpenAIEmbeddingResponse::class.java)
                    .retryWhen(createRetryPolicy())
                    .map { embeddingResponse ->
                        val embedding = embeddingResponse.data.firstOrNull()?.embedding
                            ?: throw RuntimeException("No se pudo generar el embedding")

                        ImageEmbeddingResult(
                            embedding = embedding.map { it.toDouble() }.joinToString(","),
                            model = embeddingModel,
                            confidence = BigDecimal("0.95"),
                            dimensions = embeddingResponse.data.firstOrNull()?.embedding?.size ?: EMBEDDING_DIMENSIONS
                        )
                    }
            }
            .doOnError { error ->
                logger.error("Error generando embedding con OpenAI: ${error.message}", error)
            }
    }

    /**
     * Analiza imagen completa usando GPT-4 Vision
     */
    fun analyzeImage(imageBytes: ByteArray): Mono<ImageAnalysisResult> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        val requestBody = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to """
                                Analiza esta imagen de producto y extrae la siguiente información en formato JSON:
                                
                                1. **Objetos detectados**: Lista de objetos visibles en la imagen
                                2. **Texto extraído**: Todo el texto visible en la imagen
                                3. **Logos detectados**: Marcas o logos visibles
                                4. **Códigos de barras**: Si hay códigos de barras visibles
                                5. **Colores dominantes**: Los 5 colores más prominentes
                                6. **Categoría sugerida**: Categoría de producto más apropiada
                                7. **Rango de precio**: bajo, medio, alto, premium
                                8. **Tags de uso**: Etiquetas que describen el uso del producto
                                9. **Marca**: Nombre de la marca si es visible
                                10. **Modelo**: Número de modelo si es visible
                                
                                Responde SOLO con el JSON, sin texto adicional.
                            """.trimIndent()
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/jpeg;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 2000,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                val content = response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo analizar la imagen")

                try {
                    // Extraer JSON del contenido (puede estar envuelto en bloques de código markdown)
                    val jsonContent = extractJsonFromContent(content)
                    objectMapper.readValue(jsonContent, ImageAnalysisResult::class.java)
                } catch (e: Exception) {
                    logger.error("Error parseando respuesta de OpenAI: $content", e)
                    throw RuntimeException("Error parseando análisis de imagen")
                }
            }
            .doOnError { error ->
                logger.error("Error analizando imagen con OpenAI: ${error.message}", error)
            }
    }

    /**
     * Infiere categoría de producto
     */
    fun inferProductCategory(objects: List<String>, text: String, logos: List<String>): Mono<String> {
        val prompt = """
            Basándote en la siguiente información de un producto, sugiere la categoría más apropiada:
            
            Objetos detectados: ${objects.joinToString(", ")}
            Texto extraído: $text
            Logos detectados: ${logos.joinToString(", ")}
            
            Categorías disponibles: Electrónicos, Ropa, Hogar, Deportes, Belleza, Alimentos, Bebidas, 
            Juguetes, Libros, Herramientas, Jardín, Automotriz, Salud, Mascotas, Oficina, Otros
            
            Responde SOLO con el nombre de la categoría, sin texto adicional.
        """.trimIndent()

        return callOpenAI(prompt)
    }

    /**
     * Infiere rango de precio
     */
    fun inferPriceRange(brand: String?, category: String, objects: List<String>): Mono<String> {
        val prompt = """
            Basándote en la siguiente información, sugiere el rango de precio más apropiado:
            
            Marca: ${brand ?: "No especificada"}
            Categoría: $category
            Objetos: ${objects.joinToString(", ")}
            
            Rangos disponibles: bajo, medio, alto, premium
            
            Responde SOLO con el rango, sin texto adicional.
        """.trimIndent()

        return callOpenAI(prompt)
    }

    /**
     * Infiere tags de uso
     */
    fun inferUsageTags(category: String, objects: List<String>, text: String): Mono<List<String>> {
        val prompt = """
            Basándote en la siguiente información, sugiere tags de uso apropiados:
            
            Categoría: $category
            Objetos: ${objects.joinToString(", ")}
            Texto: $text
            
            Sugiere entre 3-8 tags relevantes. Responde SOLO con los tags separados por comas, sin texto adicional.
        """.trimIndent()

        return callOpenAI(prompt)
            .map { response ->
                response.split(",").map { it.trim() }.filter { it.isNotBlank() }
            }
    }

    /**
     * Analiza una imagen de producto para identificación (NUEVO FLUJO UNIFICADO)
     * Extrae todos los campos necesarios en UNA SOLA llamada a GPT-4 Vision.
     *
     * Campos extraídos:
     * - brand_name: Marca del producto
     * - model_number: Número de modelo
     * - inferred_category: Categoría inferida
     * - dominant_colors: Colores dominantes
     * - detected_logos: Logos detectados (array)
     * - detected_objects: Objetos detectados (array)
     * - inferred_usage_tags: Tags de uso inferidos
     * - image_tags: Tags visuales de la imagen
     */
    fun analyzeProductForIdentification(imageBytes: ByteArray): Mono<VisionAnalysisResult> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        logger.info("🔍 Iniciando análisis unificado de imagen con GPT-4 Vision")

        val requestBody = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to """
                                Analiza esta imagen de producto y extrae la información en formato JSON.

                                Extrae los siguientes campos:
                                1. brand_name: Nombre de la marca visible (string o null si no es visible)
                                2. model_number: Número de modelo visible (string o null si no es visible)
                                3. inferred_category: Categoría del producto (Electrónicos, Herramientas, Hogar, Ropa, Alimentos, Bebidas, Belleza, Deportes, Juguetes, Jardín, Automotriz, Salud, Mascotas, Oficina, Otros)
                                4. dominant_colors: Array de colores dominantes en la imagen (ej: ["rojo", "negro", "blanco"])
                                5. detected_logos: Array de logos/marcas visibles en la imagen (ej: ["Stanley", "DeWalt"])
                                6. detected_objects: Array de objetos detectados en la imagen (ej: ["martillo", "destornillador", "maletín"])
                                7. inferred_usage_tags: Array de tags que describen el uso del producto (ej: ["profesional", "taller", "construcción"])
                                8. image_tags: Array de tags visuales descriptivos (ej: ["amarillo", "metálico", "kit", "herramienta"])
                                9. product_name: Nombre sugerido para el producto
                                10. product_description: Descripción breve del producto

                                Responde SOLO con el JSON, sin texto adicional ni bloques de código markdown.
                                Ejemplo de respuesta:
                                {
                                  "brand_name": "Stanley",
                                  "model_number": "STMT74101",
                                  "inferred_category": "Herramientas",
                                  "dominant_colors": ["amarillo", "negro"],
                                  "detected_logos": ["Stanley"],
                                  "detected_objects": ["maletín", "llaves", "destornilladores"],
                                  "inferred_usage_tags": ["profesional", "taller"],
                                  "image_tags": ["herramienta", "kit", "amarillo"],
                                  "product_name": "Kit de Herramientas Stanley",
                                  "product_description": "Maletín de herramientas profesional marca Stanley"
                                }
                            """.trimIndent()
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/jpeg;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 1500,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                val content = response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo analizar la imagen")

                try {
                    val jsonContent = extractJsonFromContent(content)
                    logger.info("✅ Análisis Vision completado: $jsonContent")
                    objectMapper.readValue(jsonContent, VisionAnalysisResult::class.java)
                } catch (e: Exception) {
                    logger.error("Error parseando respuesta de Vision: $content", e)
                    throw RuntimeException("Error parseando análisis de imagen: ${e.message}")
                }
            }
            .doOnError { error ->
                logger.error("❌ Error en análisis Vision: ${error.message}", error)
            }
    }

    /**
     * Detecta múltiples productos en una imagen usando GPT-4 Vision
     * Retorna una lista de productos detectados con sus posiciones aproximadas
     */
    fun detectMultipleProducts(imageBytes: ByteArray): Mono<MultipleProductsDetectionResult> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        val requestBody = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to """
                                Analiza esta imagen y detecta TODOS los productos visibles.

                                Para CADA producto detectado, proporciona:
                                1. nombre: Nombre descriptivo del producto
                                2. marca: Marca si es visible (o null)
                                3. modelo: Modelo si es visible (o null)
                                4. categoria: Categoría del producto
                                5. posicion: Posición en la imagen usando este sistema:
                                   - "superior-izquierda", "superior-centro", "superior-derecha"
                                   - "centro-izquierda", "centro", "centro-derecha"
                                   - "inferior-izquierda", "inferior-centro", "inferior-derecha"
                                6. confianza: Qué tan seguro estás (0.0 a 1.0)
                                7. descripcion: Breve descripción del producto

                                Si solo hay UN producto que ocupa toda la imagen, usa posicion="completa".

                                Responde SOLO con JSON en este formato exacto:
                                {
                                  "productos_detectados": [
                                    {
                                      "nombre": "string",
                                      "marca": "string o null",
                                      "modelo": "string o null",
                                      "categoria": "string",
                                      "posicion": "string",
                                      "confianza": 0.95,
                                      "descripcion": "string"
                                    }
                                  ],
                                  "total_productos": 1,
                                  "imagen_tipo": "producto_unico | multiples_productos | estante | caja"
                                }
                            """.trimIndent()
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/jpeg;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 2000,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                val content = response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo detectar productos en la imagen")

                try {
                    val jsonContent = extractJsonFromContent(content)
                    logger.info("Respuesta de detección múltiple: $jsonContent")
                    objectMapper.readValue(jsonContent, MultipleProductsDetectionResult::class.java)
                } catch (e: Exception) {
                    logger.error("Error parseando detección múltiple: $content", e)
                    throw RuntimeException("Error parseando detección de productos: ${e.message}")
                }
            }
            .doOnError { error ->
                logger.error("Error detectando múltiples productos: ${error.message}", error)
            }
    }

    /**
     * Detecta múltiples productos en una imagen y retorna una lista de VisionAnalysisResult
     * Compatible con el flujo de identificación individual (reutiliza la misma estructura)
     *
     * @param imageBytes Bytes de la imagen
     * @return Lista de VisionAnalysisResult para cada producto detectado
     */
    fun detectMultipleProductsForIdentification(imageBytes: ByteArray): Mono<List<VisionAnalysisResult>> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        logger.info("🔍 Iniciando detección múltiple con estructura compatible para identificación")

        val requestBody = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to """
                                Tu tarea es IDENTIFICAR Y LISTAR CADA OBJETO INDIVIDUAL visible en esta imagen.
                                
                                INSTRUCCIONES CRÍTICAS:
                                - Identifica TODOS los objetos visibles, sin importar qué tan diferentes sean entre sí
                                - Si ves un laptop Y una manzana, debes listar AMBOS como productos separados
                                - Si ves 3 manzanas, lista las 3 como entradas separadas
                                - NO agrupes ni combines objetos - cada objeto es una entrada independiente
                                - Incluye productos de CUALQUIER categoría (electrónicos, alimentos, herramientas, ropa, etc.)
                                - Examina TODA la imagen cuidadosamente, incluyendo primer plano y fondo
                                
                                EJEMPLO IMPORTANTE: Si la imagen contiene:
                                - Un laptop ASUS ZenBook
                                - Una manzana roja
                                
                                Debes retornar 2 productos en el array "products":
                                [
                                  { "product_name": "Laptop ASUS ZenBook", "inferred_category": "Electrónicos", ... },
                                  { "product_name": "Manzana Roja", "inferred_category": "Alimentos", ... }
                                ]

                                Para CADA objeto/producto detectado, extrae la siguiente información:
                                1. brand_name: Nombre de la marca visible (string o null si no es visible)
                                2. model_number: Número de modelo visible (string o null si no es visible)
                                3. inferred_category: Categoría del producto (Electrónicos, Herramientas, Hogar, Ropa, Alimentos, Bebidas, Belleza, Deportes, Juguetes, Jardín, Automotriz, Salud, Mascotas, Oficina, Otros)
                                4. dominant_colors: Array de colores dominantes del producto (ej: ["rojo", "negro"])
                                5. detected_logos: Array de logos/marcas visibles en el producto (ej: ["Apple", "Samsung"])
                                6. detected_objects: Array de objetos que describen el producto (ej: ["computadora"], ["manzana"])
                                7. inferred_usage_tags: Array de tags de uso del producto (ej: ["trabajo", "alimentación"])
                                8. image_tags: Array de descriptores visuales (ej: ["metálico", "fresco"])
                                9. product_name: Nombre descriptivo claro del objeto
                                10. product_description: Descripción breve y específica del producto
                                11. bounding_box: Ubicación del objeto en la imagen usando coordenadas normalizadas (0-1)
                                    - x: coordenada horizontal de la esquina superior izquierda (0 = borde izquierdo, 1 = borde derecho)
                                    - y: coordenada vertical de la esquina superior izquierda (0 = borde superior, 1 = borde inferior)
                                    - width: ancho del rectángulo (proporción del ancho total de la imagen)
                                    - height: alto del rectángulo (proporción del alto total de la imagen)
                                    Ejemplo: {"x": 0.1, "y": 0.2, "width": 0.5, "height": 0.6}

                                IMPORTANTE: 
                                - Responde SOLO con JSON válido, sin markdown ni texto adicional
                                - El campo "total_products" debe reflejar el número REAL de objetos distintos
                                - No omitas ningún objeto visible
                                
                                Formato de respuesta:
                                {
                                  "products": [
                                    {
                                      "brand_name": "Stanley",
                                      "model_number": "STMT74101",
                                      "inferred_category": "Herramientas",
                                      "dominant_colors": ["amarillo", "negro"],
                                      "detected_logos": ["Stanley"],
                                      "detected_objects": ["martillo"],
                                      "inferred_usage_tags": ["profesional", "construcción"],
                                      "image_tags": ["herramienta", "amarillo", "metálico"],
                                      "product_name": "Martillo Stanley",
                                      "product_description": "Martillo profesional marca Stanley con mango amarillo",
                                      "bounding_box": {"x": 0.2, "y": 0.3, "width": 0.4, "height": 0.5}
                                    }
                                  ],
                                  "total_products": 1
                                }
                            """.trimIndent()
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/jpeg;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 4000,
            "temperature" to 0.3
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                val content = response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo detectar productos en la imagen")

                try {
                    val jsonContent = extractJsonFromContent(content)
                    logger.info("✅ Detección múltiple completada: $jsonContent")

                    val result = objectMapper.readValue(jsonContent, MultipleVisionAnalysisResult::class.java)
                    logger.info("📦 Detectados ${result.products.size} productos para identificación")

                    result.products
                } catch (e: Exception) {
                    logger.error("Error parseando detección múltiple: $content", e)
                    throw RuntimeException("Error parseando detección de productos: ${e.message}")
                }
            }
            .doOnError { error ->
                logger.error("❌ Error en detección múltiple para identificación: ${error.message}", error)
            }
    }

    /**
     * Escanea una factura/documento y extrae productos usando OCR con GPT-4 Vision
     *
     * Extrae:
     * - Fecha de la factura
     * - Número de factura
     * - Nombre del proveedor
     * - Lista de productos con nombre, cantidad y precio unitario
     * - Total de la factura
     */
    fun scanInvoice(imageBytes: ByteArray): Mono<InvoiceOCRResult> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        logger.info("🧾 Iniciando escaneo OCR de factura con GPT-4 Vision")

        val requestBody = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to """
                                Analiza esta imagen de factura o documento de compra y extrae la información en formato JSON.

                                Extrae los siguientes campos:
                                1. fecha_factura: Fecha de la factura en formato "YYYY-MM-DD" (o null si no es visible)
                                2. numero_factura: Número de la factura (o null si no es visible)
                                3. proveedor: Nombre del proveedor/vendedor (o null si no es visible)
                                4. productos: Array de productos con la siguiente estructura para cada uno:
                                   - nombre: Nombre del producto (string)
                                   - cantidad: Cantidad (número entero)
                                   - precio_unitario: Precio por unidad (número decimal)
                                   - confianza: Qué tan seguro estás de la extracción (0.0 a 1.0)
                                   - notas: Cualquier observación relevante (o null)
                                5. total_factura: Total de la factura (número decimal o null)
                                6. texto_crudo: Todo el texto extraído de la factura (para referencia)
                                7. confianza_general: Confianza general del escaneo (0.0 a 1.0)

                                IMPORTANTE:
                                - Extrae TODOS los productos que puedas identificar
                                - Si no puedes leer el precio, usa 0.0 y confianza baja
                                - Si la cantidad no está clara, asume 1
                                - Los nombres de productos deben ser descriptivos

                                Responde SOLO con el JSON, sin texto adicional ni bloques de código markdown.
                                Ejemplo de respuesta:
                                {
                                  "fecha_factura": "2024-01-15",
                                  "numero_factura": "FAC-001234",
                                  "proveedor": "Distribuidora ABC",
                                  "productos": [
                                    {
                                      "nombre": "Arroz Diana 500g",
                                      "cantidad": 10,
                                      "precio_unitario": 2500.0,
                                      "confianza": 0.95,
                                      "notas": null
                                    },
                                    {
                                      "nombre": "Aceite Girasol 1L",
                                      "cantidad": 5,
                                      "precio_unitario": 8500.0,
                                      "confianza": 0.85,
                                      "notas": "Precio aproximado"
                                    }
                                  ],
                                  "total_factura": 67500.0,
                                  "texto_crudo": "FACTURA DE VENTA...",
                                  "confianza_general": 0.9
                                }
                            """.trimIndent()
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/jpeg;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 4000,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                val content = response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo escanear la factura")

                try {
                    val jsonContent = extractJsonFromContent(content)
                    logger.info("✅ Escaneo OCR completado: $jsonContent")
                    objectMapper.readValue(jsonContent, InvoiceOCRResult::class.java)
                } catch (e: Exception) {
                    logger.error("Error parseando respuesta de OCR: $content", e)
                    throw RuntimeException("Error parseando escaneo de factura: ${e.message}")
                }
            }
            .doOnError { error ->
                logger.error("❌ Error en escaneo OCR: ${error.message}", error)
            }
    }

    /**
     * Analiza un producto específico de una región de imagen recortada
     */
    fun analyzeProductRegion(imageBytes: ByteArray, productHint: String?): Mono<ImageAnalysisResult> {
        val base64Image = Base64.getEncoder().encodeToString(imageBytes)

        val hintText = if (productHint != null) {
            "Se espera encontrar: $productHint. "
        } else ""

        val requestBody = mapOf(
            "model" to model,
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to listOf(
                        mapOf(
                            "type" to "text",
                            "text" to """
                                ${hintText}Analiza esta imagen de producto y extrae la siguiente información en formato JSON:

                                1. **Objetos detectados**: Lista de objetos visibles en la imagen
                                2. **Texto extraído**: Todo el texto visible en la imagen
                                3. **Logos detectados**: Marcas o logos visibles
                                4. **Códigos de barras**: Si hay códigos de barras visibles
                                5. **Colores dominantes**: Los 5 colores más prominentes
                                6. **Categoría sugerida**: Categoría de producto más apropiada
                                7. **Rango de precio**: bajo, medio, alto, premium
                                8. **Tags de uso**: Etiquetas que describen el uso del producto
                                9. **Marca**: Nombre de la marca si es visible
                                10. **Modelo**: Número de modelo si es visible

                                Responde SOLO con el JSON, sin texto adicional.
                            """.trimIndent()
                        ),
                        mapOf(
                            "type" to "image_url",
                            "image_url" to mapOf(
                                "url" to "data:image/jpeg;base64,$base64Image"
                            )
                        )
                    )
                )
            ),
            "max_tokens" to 2000,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                val content = response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo analizar la región de imagen")

                try {
                    val jsonContent = extractJsonFromContent(content)
                    objectMapper.readValue(jsonContent, ImageAnalysisResult::class.java)
                } catch (e: Exception) {
                    logger.error("Error parseando análisis de región: $content", e)
                    throw RuntimeException("Error parseando análisis de imagen")
                }
            }
            .doOnError { error ->
                logger.error("Error analizando región de imagen: ${error.message}", error)
            }
    }

    private fun callOpenAI(prompt: String): Mono<String> {
        val requestBody = mapOf(
            "model" to "gpt-3.5-turbo",
            "messages" to listOf(
                mapOf(
                    "role" to "user",
                    "content" to prompt
                )
            ),
            "max_tokens" to 100,
            "temperature" to 0.1
        )

        return webClient.post()
            .uri("$OPENAI_API_URL/chat/completions")
            .header("Authorization", "Bearer $apiKey")
            .header("Content-Type", "application/json")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(OpenAIChatResponse::class.java)
            .retryWhen(createRetryPolicy())
            .map { response ->
                response.choices.firstOrNull()?.message?.content
                    ?: throw RuntimeException("No se pudo obtener respuesta de OpenAI")
            }
            .doOnError { error ->
                logger.error("Error llamando a OpenAI: ${error.message}", error)
            }
    }

    /**
     * Recorta una imagen usando coordenadas normalizadas de bounding box
     *
     * @param imageBytes Bytes de la imagen completa
     * @param boundingBox Coordenadas normalizadas (0-1) del área a recortar
     * @param format Formato de la imagen de salida (JPEG, PNG)
     * @return Bytes de la imagen recortada
     */
    fun cropImage(
        imageBytes: ByteArray,
        boundingBox: NormalizedBoundingBox,
        format: String = "PNG"  // Cambiado a PNG para mejor compatibilidad
    ): ByteArray {
        try {
            // Leer imagen original
            val inputStream = ByteArrayInputStream(imageBytes)
            val originalImage = ImageIO.read(inputStream)
                ?: throw RuntimeException("No se pudo leer la imagen")

            val width = originalImage.width
            val height = originalImage.height

            // Convertir coordenadas normalizadas a píxeles
            val x = (boundingBox.x * width).toInt().coerceIn(0, width - 1)
            val y = (boundingBox.y * height).toInt().coerceIn(0, height - 1)
            val cropWidth = (boundingBox.width * width).toInt().coerceIn(1, width - x)
            val cropHeight = (boundingBox.height * height).toInt().coerceIn(1, height - y)

            logger.info("Recortando imagen: original=${width}x${height}, crop=${cropWidth}x${cropHeight} at ($x,$y)")

            // Validar que el recorte tenga dimensiones válidas
            if (cropWidth <= 0 || cropHeight <= 0) {
                throw RuntimeException("Dimensiones de recorte inválidas: ${cropWidth}x${cropHeight}")
            }

            // Recortar imagen
            val croppedImage = originalImage.getSubimage(x, y, cropWidth, cropHeight)

            // Convertir a bytes usando PNG (más robusto que JPEG)
            val outputStream = ByteArrayOutputStream()
            val writeSuccess = ImageIO.write(croppedImage, format, outputStream)

            if (!writeSuccess) {
                throw RuntimeException("ImageIO.write retornó false al escribir formato $format")
            }

            val croppedBytes = outputStream.toByteArray()

            // Validar que el resultado no esté vacío
            if (croppedBytes.isEmpty()) {
                throw RuntimeException("El recorte resultó en un array vacío")
            }

            logger.info("Recorte exitoso - Tamaño resultado: ${croppedBytes.size} bytes, formato: $format")
            return croppedBytes

        } catch (e: Exception) {
            logger.error("Error recortando imagen: ${e.message}", e)
            // Si falla el recorte, lanzar el error (no retornar imagen original)
            throw RuntimeException("Error al recortar imagen: ${e.message}", e)
        }
    }

    /**
     * Extrae JSON del contenido de OpenAI, removiendo bloques de código markdown si están presentes
     */
    private fun extractJsonFromContent(content: String): String {
        return content.trim().let { trimmedContent ->
            // Si el contenido está envuelto en bloques de código markdown (```json ... ```)
            if (trimmedContent.startsWith("```json") && trimmedContent.endsWith("```")) {
                trimmedContent
                    .removePrefix("```json")
                    .removeSuffix("```")
                    .trim()
            }
            // Si el contenido está envuelto en bloques de código genéricos (``` ... ```)
            else if (trimmedContent.startsWith("```") && trimmedContent.endsWith("```")) {
                trimmedContent
                    .removePrefix("```")
                    .removeSuffix("```")
                    .trim()
            }
            // Si no está envuelto, devolver tal como está
            else {
                trimmedContent
            }
        }
    }
}

// Clases de respuesta de OpenAI
data class OpenAIEmbeddingResponse(
    val data: List<EmbeddingData>
)

data class EmbeddingData(
    val embedding: List<Float>
)

data class OpenAIChatResponse(
    val choices: List<Choice>
)

data class Choice(
    val message: Message
)

data class Message(
    val content: String
)

data class ImageAnalysisResult(
    @com.fasterxml.jackson.annotation.JsonProperty("Objetos detectados")
    @JsonDeserialize(using = StringOrListDeserializer::class)
    val objects: List<String> = emptyList(),
    @com.fasterxml.jackson.annotation.JsonProperty("Texto extraído")
    @JsonDeserialize(using = StringOrArrayDeserializer::class)
    val text: String = "",
    @com.fasterxml.jackson.annotation.JsonProperty("Logos detectados")
    @JsonDeserialize(using = StringOrListDeserializer::class)
    val logos: List<String> = emptyList(),
    @com.fasterxml.jackson.annotation.JsonProperty("Códigos de barras")
    val barcodes: Any = false, // Puede ser boolean o List<String>
    @com.fasterxml.jackson.annotation.JsonProperty("Colores dominantes")
    @JsonDeserialize(using = StringOrListDeserializer::class)
    val colors: List<String> = emptyList(),
    @com.fasterxml.jackson.annotation.JsonProperty("Categoría sugerida")
    val category: String = "",
    @com.fasterxml.jackson.annotation.JsonProperty("Rango de precio")
    val priceRange: String = "",
    @com.fasterxml.jackson.annotation.JsonProperty("Tags de uso")
    @JsonDeserialize(using = StringOrListDeserializer::class)
    val usageTags: List<String> = emptyList(),
    @com.fasterxml.jackson.annotation.JsonProperty("Marca")
    val brand: String? = null,
    @com.fasterxml.jackson.annotation.JsonProperty("Modelo")
    val model: String? = null
)

data class OpenAIVisionResponse(
    val choices: List<VisionChoice>
)

data class VisionChoice(
    val message: VisionMessage
)

data class VisionMessage(
    val content: String
)

// Clases para detección múltiple de productos
data class MultipleProductsDetectionResult(
    @com.fasterxml.jackson.annotation.JsonProperty("productos_detectados")
    val productosDetectados: List<DetectedProductInfo> = emptyList(),
    @com.fasterxml.jackson.annotation.JsonProperty("total_productos")
    val totalProductos: Int = 0,
    @com.fasterxml.jackson.annotation.JsonProperty("imagen_tipo")
    val imagenTipo: String = "producto_unico"
)

data class DetectedProductInfo(
    val nombre: String = "",
    val marca: String? = null,
    val modelo: String? = null,
    val categoria: String = "",
    val posicion: String = "completa",
    val confianza: Double = 0.0,
    val descripcion: String = ""
) {
    /**
     * Convierte la posición textual a coordenadas normalizadas (0-1)
     * Retorna un par de (x, y, width, height)
     */
    fun getBoundingBox(): BoundingBoxCoordinates {
        return when (posicion.lowercase()) {
            "superior-izquierda" -> BoundingBoxCoordinates(0.0, 0.0, 0.33, 0.33)
            "superior-centro" -> BoundingBoxCoordinates(0.33, 0.0, 0.33, 0.33)
            "superior-derecha" -> BoundingBoxCoordinates(0.66, 0.0, 0.34, 0.33)
            "centro-izquierda" -> BoundingBoxCoordinates(0.0, 0.33, 0.33, 0.33)
            "centro" -> BoundingBoxCoordinates(0.33, 0.33, 0.33, 0.33)
            "centro-derecha" -> BoundingBoxCoordinates(0.66, 0.33, 0.34, 0.33)
            "inferior-izquierda" -> BoundingBoxCoordinates(0.0, 0.66, 0.33, 0.34)
            "inferior-centro" -> BoundingBoxCoordinates(0.33, 0.66, 0.33, 0.34)
            "inferior-derecha" -> BoundingBoxCoordinates(0.66, 0.66, 0.34, 0.34)
            "completa", "toda" -> BoundingBoxCoordinates(0.0, 0.0, 1.0, 1.0)
            else -> BoundingBoxCoordinates(0.0, 0.0, 1.0, 1.0) // Default: toda la imagen
        }
    }
}

data class BoundingBoxCoordinates(
    val x: Double,      // Coordenada X normalizada (0-1)
    val y: Double,      // Coordenada Y normalizada (0-1)
    val width: Double,  // Ancho normalizado (0-1)
    val height: Double  // Alto normalizado (0-1)
)

/**
 * Resultado del análisis unificado de Vision para identificación de productos.
 * Todos los campos necesarios se extraen en UNA sola llamada a GPT-4 Vision.
 */
data class VisionAnalysisResult(
    @com.fasterxml.jackson.annotation.JsonProperty("brand_name")
    val brandName: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("model_number")
    val modelNumber: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("inferred_category")
    val inferredCategory: String = "Otros",

    @com.fasterxml.jackson.annotation.JsonProperty("dominant_colors")
    val dominantColors: List<String> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("detected_logos")
    val detectedLogos: List<String> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("detected_objects")
    val detectedObjects: List<String> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("inferred_usage_tags")
    val inferredUsageTags: List<String> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("image_tags")
    val imageTags: List<String> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("product_name")
    val productName: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("product_description")
    val productDescription: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("bounding_box")
    val boundingBox: NormalizedBoundingBox? = null
)

/**
 * Bounding box normalizada (coordenadas en rango 0-1)
 * x, y: coordenadas de la esquina superior izquierda
 * width, height: ancho y alto del rectángulo
 */
data class NormalizedBoundingBox(
    val x: Double,
    val y: Double,
    val width: Double,
    val height: Double
)

/**
 * Resultado de la detección múltiple de productos para identificación.
 * Wrapper para deserializar la respuesta JSON que contiene múltiples VisionAnalysisResult.
 */
data class MultipleVisionAnalysisResult(
    @com.fasterxml.jackson.annotation.JsonProperty("products")
    val products: List<VisionAnalysisResult> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("total_products")
    val totalProducts: Int = 0
)

// ============================================================================
// MODELOS PARA ESCANEO DE FACTURAS (OCR)
// ============================================================================

/**
 * Producto extraído de una factura mediante OCR
 */
data class InvoiceProductExtracted(
    @com.fasterxml.jackson.annotation.JsonProperty("nombre")
    val nombre: String = "",

    @com.fasterxml.jackson.annotation.JsonProperty("cantidad")
    val cantidad: Int = 1,

    @com.fasterxml.jackson.annotation.JsonProperty("precio_unitario")
    val precioUnitario: Double = 0.0,

    @com.fasterxml.jackson.annotation.JsonProperty("confianza")
    val confianza: Double = 0.0,

    @com.fasterxml.jackson.annotation.JsonProperty("notas")
    val notas: String? = null
)

/**
 * Resultado del escaneo OCR de una factura
 */
data class InvoiceOCRResult(
    @com.fasterxml.jackson.annotation.JsonProperty("fecha_factura")
    val fechaFactura: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("numero_factura")
    val numeroFactura: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("proveedor")
    val proveedor: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("productos")
    val productos: List<InvoiceProductExtracted> = emptyList(),

    @com.fasterxml.jackson.annotation.JsonProperty("total_factura")
    val totalFactura: Double? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("texto_crudo")
    val textoCrudo: String? = null,

    @com.fasterxml.jackson.annotation.JsonProperty("confianza_general")
    val confianzaGeneral: Double = 0.0
)
