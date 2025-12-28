package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.product

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.ProductDisplayDTO
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.toDisplay
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.product.ProductUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.model.filestorage.FileStorageService
import com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.product.utils.ImageUtils
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.core.io.buffer.DataBufferUtils
import org.springframework.http.HttpStatus
import org.springframework.http.codec.multipart.FilePart
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

@Component
class ProductHandler(
    private val productUseCase: ProductUseCase,
    private val fileStorageService: FileStorageService
) {
    private val logger: Logger = LoggerFactory.getLogger(ProductHandler::class.java)
    private val EXPIRATION_DATE_DEFAULT: LocalDate = LocalDate.now().plusYears(1)
    private val STOCK_MINIUM_DEFAULT: Int = 1

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Product::class.java)
            .flatMap { productUseCase.create(it) }
            .map { it.toDisplay() }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun createWithRecognition(request: ServerRequest): Mono<ServerResponse> {
        logger.info("Recibida solicitud de creación con reconocimiento automático")

        return request.multipartData()
            .flatMap { multipartData ->
                val parts = multipartData.toSingleValueMap()

                // Extraer archivo de imagen primero
                val imagePart = parts["image"] as? FilePart
                    ?: return@flatMap Mono.error<ServerResponse>(IllegalArgumentException("Imagen es requerida"))

                // Leer bytes de la imagen
                DataBufferUtils.join(imagePart.content())
                    .map { dataBuffer ->
                        val bytes = ByteArray(dataBuffer.readableByteCount())
                        dataBuffer.read(bytes)
                        DataBufferUtils.release(dataBuffer)
                        bytes
                    }
                    .flatMap { imageBytes ->
                        // Detectar tipo de imagen
                        val imageType = ImageUtils.detectImageTypeFromFilePart(imagePart, imageBytes)

                        if (!ImageUtils.isSupportedImageType(imageType)) {
                            return@flatMap Mono.error<ServerResponse>(
                                IllegalArgumentException("Tipo de imagen no soportado: ${imageType.format}. Tipos soportados: jpg, png, gif, webp, bmp, tiff")
                            )
                        }

                        // Extraer datos del formulario de forma reactiva
                        val nameMono = DataBufferUtils.join(
                            parts["name"]?.content() ?: return@flatMap Mono.error<ServerResponse>(
                                IllegalArgumentException("Nombre es requerido")
                            )
                        )
                            .map { it.toString(Charsets.UTF_8) }
                            .defaultIfEmpty("")

                        val descriptionMono = DataBufferUtils.join(
                            parts["description"]?.content() ?: return@flatMap Mono.error<ServerResponse>(
                                IllegalArgumentException("Descripción es requerida")
                            )
                        )
                            .map { it.toString(Charsets.UTF_8) }
                            .defaultIfEmpty("")

                        val categoryIdMono = DataBufferUtils.join(
                            parts["categoryId"]?.content() ?: return@flatMap Mono.error<ServerResponse>(
                                IllegalArgumentException("CategoryId es requerido")
                            )
                        )
                            .map { it.toString(Charsets.UTF_8) }
                            .map { categoryIdStr ->
                                try {
                                    categoryIdStr.toLong()
                                } catch (e: NumberFormatException) {
                                    1L
                                }
                            }
                            .defaultIfEmpty(1L)

                        // Obtener el minimo stock de la peticion
                        val stockMinimum = parts["stockMinimum"]?.let { stockPart ->
                            DataBufferUtils.join(stockPart.content())
                                .map { it.toString(Charsets.UTF_8).toIntOrNull() ?: 0 }
                        } ?: Mono.just(STOCK_MINIUM_DEFAULT)

                        val expirationDate = parts["expirationDate"]?.let { expPart ->
                            DataBufferUtils.join(expPart.content())
                                .map { it.toString(Charsets.UTF_8) }
                                .map { dateStr -> LocalDate.parse(dateStr) }
                        } ?: Mono.just(EXPIRATION_DATE_DEFAULT)

                        // Combinar todos los datos reactivamente
                        Mono.zip(nameMono, descriptionMono, categoryIdMono, stockMinimum, expirationDate)
                            .flatMap { tuple ->
                                val product = Product(
                                    name = tuple.t1,
                                    description = tuple.t2,
                                    categoryId = tuple.t3,
                                    stockMinimum = tuple.t4,
                                    expirationDate = tuple.t5,
                                    productImage = imageBytes,
                                    imageFormat = imageType.format,
                                    imageSizeBytes = imageBytes.size,
                                    imageMetadata = ImageUtils.buildImageMetadata(imageType, imagePart, imageBytes.size)
                                )

                                productUseCase.createWithImageRecognition(product)
                                    .map { it.toDisplay() }
                            }
                    }
            }
            .flatMap { result ->
                logger.info("Producto creado exitosamente con reconocimiento automático")
                ServerResponse.status(HttpStatus.CREATED).bodyValue(result)
            }
            .doOnError { error ->
                logger.error("Error en creación con reconocimiento: ${error.message}", error)
            }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Product::class.java)
            .flatMap { productUseCase.update(id, it) }
            .map { it.toDisplay() }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(
            productUseCase.findAll(page, size).map { it.toDisplay() },
            ProductDisplayDTO::class.java
        )
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return productUseCase.findById(id)
            .map { it.toDisplay() }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findByName(request: ServerRequest): Mono<ServerResponse> {
        val name = request.queryParam("name").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(
            productUseCase.findByName(name, page, size).map { it.toDisplay() },
            ProductDisplayDTO::class.java
        )
    }

    fun findByCategoryId(request: ServerRequest): Mono<ServerResponse> {
        val categoryId = request.queryParam("categoryId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("categoryId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(
            productUseCase.findByCategoryId(categoryId, page, size).map { it.toDisplay() },
            ProductDisplayDTO::class.java
        )
    }

    fun findByStockQuantityGreaterThan(request: ServerRequest): Mono<ServerResponse> {
        val quantity = request.queryParam("quantity").map { it.toInt() }.orElse(0)
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)

        return ServerResponse.ok()
            .body(
                productUseCase.findByStockQuantityGreaterThan(quantity, page, size).map { it.toDisplay() },
                ProductDisplayDTO::class.java
            )
    }

    fun findByExpirationDateBefore(request: ServerRequest): Mono<ServerResponse> {
        val expirationDate =
            request.queryParam("expirationDate").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)
                ?: return ServerResponse.badRequest()
                    .bodyValue("expirationDate es requerido y debe tener el formato yyyy-MM-dd")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)

        return ServerResponse.ok()
            .body(
                productUseCase.findByExpirationDateBefore(expirationDate, page, size).map { it.toDisplay() },
                ProductDisplayDTO::class.java
            )
    }

    // Endpoints de búsqueda por reconocimiento automático
    fun findByBarcodeData(request: ServerRequest): Mono<ServerResponse> {
        val barcodeData = request.queryParam("barcodeData").orElse("")
        if (barcodeData.isBlank()) {
            return ServerResponse.badRequest().bodyValue("barcodeData es requerido")
        }
        return productUseCase.findByBarcodeData(barcodeData)
            .map { it.toDisplay() }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    /**
     * Renueva la URL firmada de imagen de un producto
     * Útil cuando la URL ha expirado y necesita ser regenerada
     */
    fun refreshImageUrl(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return productUseCase.findById(id)
            .flatMap { product ->
                if (product.imageUrl != null) {
                    fileStorageService.generatePresignedUrl(product.imageUrl)
                        .map { newUrl ->
                            // El servicio ya devuelve la URL del proxy, no necesitamos procesarla aquí
                            mapOf(
                                "productId" to product.id,
                                "imageUrl" to newUrl,
                                "message" to "URL de imagen renovada exitosamente"
                            )
                        }
                        .flatMap { ServerResponse.ok().bodyValue(it) }
                } else {
                    ServerResponse.badRequest().bodyValue(
                        mapOf(
                            "error" to "El producto no tiene una imagen asociada",
                            "productId" to product.id
                        )
                    )
                }
            }
            .onErrorResume { error ->
                logger.error("Error al renovar URL de imagen para producto $id", error)
                ServerResponse.status(HttpStatus.INTERNAL_SERVER_ERROR).bodyValue(
                    mapOf(
                        "error" to "Error al renovar URL de imagen: ${error.message}",
                        "productId" to id
                    )
                )
            }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return productUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }
}