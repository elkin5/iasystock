package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.invoicescan

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.InvoiceOCRResult
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.OpenAIService
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Base64
import java.util.UUID

/**
 * Handler para endpoints de escaneo de facturas con OCR
 *
 * Endpoints:
 * - POST /api/v1/invoice-scan/scan - Escanea factura y extrae productos
 * - GET /api/v1/invoice-scan/search-products - Busca productos por nombre
 * - POST /api/v1/invoice-scan/confirm - Confirma y registra productos
 */
@Component
class InvoiceScanHandler(
    private val openAIService: OpenAIService,
    private val productRepository: ProductRepository
) {

    private val logger: Logger = LoggerFactory.getLogger(InvoiceScanHandler::class.java)

    /**
     * POST /api/v1/invoice-scan/scan
     *
     * Escanea una factura/documento y extrae los productos
     */
    fun scanInvoice(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== POST /api/v1/invoice-scan/scan ===")

        return request.bodyToMono(InvoiceScanRequestDTO::class.java)
            .flatMap { requestDTO ->
                val startTime = System.currentTimeMillis()

                // Decodificar imagen de base64
                val imageBytes = try {
                    Base64.getDecoder().decode(requestDTO.imageBase64)
                } catch (e: IllegalArgumentException) {
                    return@flatMap Mono.error<ServerResponse>(
                        IllegalArgumentException("Invalid base64 image data: ${e.message}")
                    )
                }

                // Validar tamaño de imagen (max 10MB)
                if (imageBytes.size > 10 * 1024 * 1024) {
                    return@flatMap Mono.error<ServerResponse>(
                        IllegalArgumentException("Image size exceeds 10MB limit")
                    )
                }

                logger.info("Procesando imagen de factura: ${imageBytes.size} bytes")

                // Ejecutar OCR con OpenAI
                openAIService.scanInvoice(imageBytes)
                    .flatMap { ocrResult ->
                        // Buscar productos coincidentes en la base de datos
                        matchProductsWithDatabase(ocrResult, requestDTO.defaultProfitMargin)
                            .map { matchedProducts ->
                                val processingTime = System.currentTimeMillis() - startTime

                                InvoiceScanResultDTO(
                                    status = if (matchedProducts.isNotEmpty()) "SUCCESS" else "NO_PRODUCTS_FOUND",
                                    invoiceDate = parseDate(ocrResult.fechaFactura),
                                    invoiceNumber = ocrResult.numeroFactura,
                                    supplierName = ocrResult.proveedor,
                                    products = matchedProducts,
                                    totalProducts = matchedProducts.size,
                                    matchedProducts = matchedProducts.count { it.matchedProduct != null },
                                    unmatchedProducts = matchedProducts.count { it.matchedProduct == null },
                                    totalAmount = matchedProducts.sumOf { it.unitPrice * it.quantity },
                                    requiresValidation = matchedProducts.any { it.extractionConfidence < 0.8 },
                                    processingTimeMs = processingTime.toInt(),
                                    rawText = ocrResult.textoCrudo
                                )
                            }
                    }
                    .flatMap { result ->
                        logger.info(
                            "✅ Escaneo completado: ${result.totalProducts} productos, " +
                            "${result.matchedProducts} vinculados, " +
                            "${result.processingTimeMs}ms"
                        )

                        ServerResponse
                            .ok()
                            .contentType(MediaType.APPLICATION_JSON)
                            .bodyValue(ApiResponseDTO(
                                success = true,
                                data = result,
                                message = "Factura escaneada exitosamente"
                            ))
                    }
            }
            .onErrorResume { error ->
                logger.error("❌ Error en escaneo de factura: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error desconocido en escaneo"
                    ))
            }
    }

    /**
     * GET /api/v1/invoice-scan/search-products?query=...&limit=10
     *
     * Busca productos por nombre para vincular manualmente
     */
    fun searchProducts(request: ServerRequest): Mono<ServerResponse> {
        val query = request.queryParam("query").orElse("")
        val limit = request.queryParam("limit")
            .map { it.toIntOrNull() ?: 10 }
            .orElse(10)

        logger.info("=== GET /api/v1/invoice-scan/search-products?query=$query&limit=$limit ===")

        if (query.isBlank()) {
            return ServerResponse
                .badRequest()
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(ApiResponseDTO<Any>(
                    success = false,
                    error = "Query parameter is required"
                ))
        }

        return productRepository.findByName(query, 0, limit)
            .map { product ->
                MatchedProductDTO(
                    id = product.id!!.toInt(),
                    name = product.name,
                    description = product.description,
                    imageUrl = product.imageUrl,
                    categoryId = product.categoryId?.toInt(),
                    stockQuantity = product.stockQuantity
                )
            }
            .collectList()
            .flatMap { products ->
                logger.info("✅ Encontrados ${products.size} productos para query: $query")

                ServerResponse
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO(
                        success = true,
                        data = products,
                        message = "${products.size} productos encontrados"
                    ))
            }
            .onErrorResume { error ->
                logger.error("❌ Error buscando productos: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error buscando productos"
                    ))
            }
    }

    /**
     * POST /api/v1/invoice-scan/confirm
     *
     * Confirma los productos y los registra en el stock
     */
    fun confirmAndRegister(request: ServerRequest): Mono<ServerResponse> {
        logger.info("=== POST /api/v1/invoice-scan/confirm ===")

        return request.bodyToMono(InvoiceConfirmationRequestDTO::class.java)
            .flatMap { requestDTO ->
                logger.info("Confirmando ${requestDTO.products.size} productos para registro")

                // Por ahora, solo retornamos éxito
                // La lógica de registro se maneja en el frontend con ProductStockCubit
                ServerResponse
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = true,
                        message = "${requestDTO.products.size} productos listos para registro"
                    ))
            }
            .onErrorResume { error ->
                logger.error("❌ Error confirmando productos: ${error.message}", error)

                ServerResponse
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(ApiResponseDTO<Any>(
                        success = false,
                        error = error.message ?: "Error confirmando productos"
                    ))
            }
    }

    /**
     * Busca productos coincidentes en la base de datos para cada producto extraído
     */
    private fun matchProductsWithDatabase(
        ocrResult: InvoiceOCRResult,
        profitMargin: Int
    ): Mono<List<InvoiceProductItemDTO>> {
        return Flux.fromIterable(ocrResult.productos)
            .flatMap { extractedProduct ->
                // Buscar producto por nombre similar
                productRepository.findByName(extractedProduct.nombre, 0, 1)
                    .next()
                    .map { matchedProduct ->
                        val salePrice = extractedProduct.precioUnitario * (1 + profitMargin / 100.0)

                        InvoiceProductItemDTO(
                            tempId = UUID.randomUUID().toString(),
                            extractedName = extractedProduct.nombre,
                            quantity = extractedProduct.cantidad,
                            unitPrice = extractedProduct.precioUnitario,
                            salePrice = salePrice,
                            profitMargin = profitMargin,
                            matchedProduct = MatchedProductDTO(
                                id = matchedProduct.id!!.toInt(),
                                name = matchedProduct.name,
                                description = matchedProduct.description,
                                imageUrl = matchedProduct.imageUrl,
                                categoryId = matchedProduct.categoryId?.toInt(),
                                stockQuantity = matchedProduct.stockQuantity
                            ),
                            extractionConfidence = extractedProduct.confianza,
                            matchConfidence = 0.7, // Confianza por búsqueda de texto
                            isConfirmed = false,
                            createAsNew = false,
                            notes = extractedProduct.notas
                        )
                    }
                    .defaultIfEmpty(
                        // No se encontró producto coincidente
                        InvoiceProductItemDTO(
                            tempId = UUID.randomUUID().toString(),
                            extractedName = extractedProduct.nombre,
                            quantity = extractedProduct.cantidad,
                            unitPrice = extractedProduct.precioUnitario,
                            salePrice = extractedProduct.precioUnitario * (1 + profitMargin / 100.0),
                            profitMargin = profitMargin,
                            matchedProduct = null,
                            extractionConfidence = extractedProduct.confianza,
                            matchConfidence = null,
                            isConfirmed = false,
                            createAsNew = true,
                            notes = extractedProduct.notas
                        )
                    )
            }
            .collectList()
    }

    /**
     * Parsea fecha desde string a LocalDate
     */
    private fun parseDate(dateString: String?): String? {
        if (dateString == null) return null

        return try {
            // Intentar parsear formato ISO
            LocalDate.parse(dateString)
            dateString
        } catch (e: Exception) {
            try {
                // Intentar otros formatos comunes
                val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
                LocalDate.parse(dateString, formatter).toString()
            } catch (e2: Exception) {
                dateString
            }
        }
    }
}

// ============================================================================
// DTOs para Request/Response
// ============================================================================

data class ApiResponseDTO<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: String? = null
)

data class InvoiceScanRequestDTO(
    val imageBase64: String,
    val imageFormat: String = "jpeg",
    val source: String = "MOBILE_APP",
    val userId: Int? = null,
    val defaultProfitMargin: Int = 30
)

data class InvoiceScanResultDTO(
    val status: String,
    val invoiceDate: String?,
    val invoiceNumber: String?,
    val supplierName: String?,
    val products: List<InvoiceProductItemDTO>,
    val totalProducts: Int,
    val matchedProducts: Int,
    val unmatchedProducts: Int,
    val totalAmount: Double,
    val requiresValidation: Boolean,
    val processingTimeMs: Int,
    val rawText: String? = null,
    val metadata: Map<String, Any> = emptyMap()
)

data class InvoiceProductItemDTO(
    val tempId: String,
    val extractedName: String,
    val quantity: Int,
    val unitPrice: Double,
    val salePrice: Double,
    val profitMargin: Int,
    val matchedProduct: MatchedProductDTO?,
    val extractionConfidence: Double,
    val matchConfidence: Double?,
    val isConfirmed: Boolean,
    val createAsNew: Boolean,
    val notes: String?
)

data class MatchedProductDTO(
    val id: Int,
    val name: String,
    val description: String?,
    val imageUrl: String?,
    val categoryId: Int?,
    val stockQuantity: Int?
)

data class InvoiceConfirmationRequestDTO(
    val products: List<ConfirmedInvoiceProductDTO>,
    val warehouseId: Int,
    val personId: Int?,
    val entryDate: String?,
    val userId: Int
)

data class ConfirmedInvoiceProductDTO(
    val productId: Int?,
    val productName: String,
    val quantity: Int,
    val entryPrice: Double,
    val salePrice: Double,
    val createAsNew: Boolean = false,
    val categoryId: Int?
)
