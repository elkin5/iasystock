package com.co.kinsoft.api.iasy_stock_api.domain.usecase.product

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.DomainException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.filestorage.FileStorageService
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.*
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ThresholdConfigRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ProductRecognitionService
import com.co.kinsoft.api.iasy_stock_api.domain.service.ProductIdentificationService
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.promotion.PromotionUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.saleitem.SaleItemUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock.StockUseCase
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.OpenAIService
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.VisionAnalysisResult
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

class ProductUseCase(
    private val productRepository: ProductRepository,
    private val stockUseCase: StockUseCase,
    private val promotionUseCase: PromotionUseCase,
    private val saleItemUseCase: SaleItemUseCase,
    private val productRecognitionService: ProductRecognitionService,
    private val fileStorageService: FileStorageService,
    private val productIdentificationService: ProductIdentificationService,
    private val thresholdConfigRepository: ThresholdConfigRepository,
    private val openAIService: OpenAIService
) {

    private val logger: Logger = LoggerFactory.getLogger(ProductUseCase::class.java)

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> =
        productRepository.findAll(page, size)

    fun findById(id: Long): Mono<Product> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID del producto debe ser un valor positivo."))
        }
        return productRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("El producto con ID $id no existe.")))
    }

    fun create(product: Product): Mono<Product> {
        return Mono.fromCallable {
            ProductValidator.validate(product)
            // Establecer stockQuantity en 0 por defecto si no se especifica
            val productWithDefaultStock = product.copy(stockQuantity = product.stockQuantity ?: 0)

            productWithDefaultStock
        }.flatMap { validatedProduct ->
            // Verificar si ya existe un producto con el mismo nombre
            productRepository.findByName(validatedProduct.name, DEFAULT_PAGE, DEFAULT_SIZE)
                .hasElements()
                .flatMap { exists ->
                    if (exists) {
                        Mono.error(AlreadyExistsException("Ya existe un producto con el nombre '${validatedProduct.name}'"))
                    } else {
                        // Si hay imagen, subirla a MinIO y procesar reconocimiento automático
                        if (validatedProduct.productImage != null && validatedProduct.productImage.isNotEmpty()) {
                            // Subir imagen a MinIO primero
                            fileStorageService.uploadProductImage(validatedProduct.productImage)
                                .flatMap { imageUrl ->
                                    // Crear producto con la URL de la imagen
                                    val productWithImageUrl = validatedProduct.copy(imageUrl = imageUrl)
                                    processProductWithRecognition(productWithImageUrl)
                                }
                        } else {
                            // Crear producto sin imagen ni reconocimiento
                            productRepository.save(validatedProduct)
                        }
                    }
                }
        }
    }

    fun createWithImageRecognition(productInput: Product): Mono<Product> {
        return Mono.fromCallable {
            val product = productInput.copy(
                stockQuantity = productInput.stockQuantity ?: 0,
                createdAt = LocalDateTime.now()
            )

            ProductValidator.validate(product)
            product
        }.flatMap { validatedProduct ->
            if (validatedProduct.productImage == null || validatedProduct.productImage.isEmpty()) {
                return@flatMap Mono.error(InvalidDataException("Se requiere una imagen para el reconocimiento automático."))
            }

            productRepository.findByName(validatedProduct.name, DEFAULT_PAGE, DEFAULT_SIZE)
                .hasElements()
                .flatMap { exists ->
                    if (exists) {
                        Mono.error(AlreadyExistsException("Ya existe un producto con el nombre '${validatedProduct.name}'"))
                    } else {
                        fileStorageService.uploadProductImage(
                            imageBytes = validatedProduct.productImage, imageFormat = validatedProduct.imageFormat!!
                        ).flatMap { imageUrl ->
                            val productWithImageUrl = validatedProduct.copy(imageUrl = imageUrl)
                            processProductWithRecognition(productWithImageUrl)
                        }
                    }
                }
        }
    }

    private fun processProductWithRecognition(product: Product): Mono<Product> {
        logger.info("Iniciando reconocimiento automático para producto: ${product.name}")

        return productRecognitionService.processProductImage(
            product.productImage!!,
            product.imageFormat ?: "jpeg"
        ).flatMap { recognitionResult ->

            // Crear producto con información de reconocimiento
            val enrichedProduct = product.copy(
                // Campos de vectores de imagen
                imageEmbedding = recognitionResult.imageEmbedding,
                embeddingModel = recognitionResult.embeddingModel,
                imageUpdatedAt = LocalDateTime.now(),
                imageHash = recognitionResult.imageHash,
                embeddingConfidence = recognitionResult.embeddingConfidence,
                similarityThreshold = BigDecimal("0.8"),
                multipleViews = null, // Se puede implementar múltiples vistas
                imageTags = recognitionResult.inferredUsageTags,
                imageQualityScore = recognitionResult.imageQualityScore,
                imageFormat = recognitionResult.imageFormat,
                imageSizeBytes = recognitionResult.imageSizeBytes,

                // Campos auto-extraíbles
                barcodeData = recognitionResult.barcodeData,
                brandName = recognitionResult.brandName ?: product.brandName,
                modelNumber = recognitionResult.modelNumber ?: product.modelNumber,
                dominantColors = recognitionResult.dominantColors,
                textOcr = recognitionResult.textOcr,
                logoDetection = recognitionResult.logoDetection,
                objectDetection = recognitionResult.objectDetection,
                recognitionAccuracy = recognitionResult.recognitionAccuracy,
                lastRecognitionAt = LocalDateTime.now(),
                recognitionCount = 1,

                // Campos inferidos automáticamente
                inferredCategory = recognitionResult.inferredCategory,
                inferredPriceRange = recognitionResult.inferredPriceRange,
                inferredUsageTags = recognitionResult.inferredUsageTags,
                confidenceScores = recognitionResult.confidenceScores
            )

            productRepository.save(enrichedProduct)
        }.doOnError { error ->
            logger.error("Error en reconocimiento automático: ${error.message}", error)
        }
    }

    fun update(id: Long, product: Product): Mono<Product> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID del producto debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            ProductValidator.validate(product)
            product
        }.flatMap {
            productRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("El producto con ID $id no existe.")))
        }.flatMap { existingProduct ->
            val updatedProduct = existingProduct.copy(
                name = product.name,
                description = product.description,
                productImage = product.productImage,
                stockQuantity = product.stockQuantity,
                expirationDate = product.expirationDate,
                categoryId = product.categoryId,
                // Campos de reconocimiento automático
                imageEmbedding = product.imageEmbedding,
                embeddingModel = product.embeddingModel,
                imageUpdatedAt = product.imageUpdatedAt,
                imageHash = product.imageHash,
                embeddingConfidence = product.embeddingConfidence,
                imageMetadata = product.imageMetadata,
                similarityThreshold = product.similarityThreshold,
                multipleViews = product.multipleViews,
                imageTags = product.imageTags,
                imageQualityScore = product.imageQualityScore,
                imageFormat = product.imageFormat,
                imageSizeBytes = product.imageSizeBytes,
                barcodeData = product.barcodeData,
                brandName = product.brandName,
                modelNumber = product.modelNumber,
                dominantColors = product.dominantColors,
                textOcr = product.textOcr,
                logoDetection = product.logoDetection,
                objectDetection = product.objectDetection,
                recognitionAccuracy = product.recognitionAccuracy,
                lastRecognitionAt = product.lastRecognitionAt,
                recognitionCount = product.recognitionCount,
                inferredCategory = product.inferredCategory,
                inferredPriceRange = product.inferredPriceRange,
                inferredUsageTags = product.inferredUsageTags,
                confidenceScores = product.confidenceScores
            )
            productRepository.save(updatedProduct)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID del producto debe ser un valor positivo."))
        }
        return productRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("El producto con ID $id no existe.")))
            .flatMap {
                stockUseCase.findByProductId(it.id, DEFAULT_PAGE, DEFAULT_SIZE)
                    .hasElements()
                    .flatMap { hasStock ->
                        if (hasStock) {
                            Mono.error(DomainException("No se puede eliminar el producto porque tiene movimientos de stock asociados."))
                        } else {
                            promotionUseCase.findByProductId(it.id, DEFAULT_PAGE, DEFAULT_SIZE)
                                .hasElements()
                                .flatMap { hasPromotions ->
                                    if (hasPromotions) {
                                        Mono.error(DomainException("No se puede eliminar el producto porque tiene promociones asociadas."))
                                    } else {
                                        saleItemUseCase.findByProductId(it.id, DEFAULT_PAGE, DEFAULT_SIZE)
                                            .hasElements()
                                            .flatMap { hasSales ->
                                                if (hasSales) {
                                                    Mono.error(DomainException("No se puede eliminar el producto porque tiene ventas asociadas."))
                                                } else {
                                                    productRepository.deleteById(id)
                                                }
                                            }
                                    }
                                }
                        }
                    }
            }
    }

    // Métodos de búsqueda existentes
    fun findByName(name: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> =
        productRepository.findByName(name, page, size)

    fun findByCategoryId(categoryId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> =
        productRepository.findByCategoryId(categoryId, page, size)

    fun findByStockQuantityGreaterThan(
        quantity: Int,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Product> =
        productRepository.findByStockQuantityGreaterThan(quantity, page, size)

    fun findByExpirationDateBefore(
        expirationDate: LocalDate,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Product> =
        productRepository.findByExpirationDateBefore(expirationDate, page, size)

    // Métodos de búsqueda por reconocimiento automático
    fun findByBarcodeData(barcodeData: String): Mono<Product> {
        if (barcodeData.isBlank()) {
            return Mono.error(InvalidDataException("Los datos del código de barras no pueden estar vacíos."))
        }
        return productRepository.findByBarcodeData(barcodeData)
            .switchIfEmpty(Mono.error(NotFoundException("No se encontró un producto con el código de barras '$barcodeData'.")))
    }

    fun findByBrandName(brandName: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> {
        if (brandName.isBlank()) {
            return Flux.error(InvalidDataException("El nombre de la marca no puede estar vacío."))
        }
        return productRepository.findByBrandName(brandName, page, size)
    }

    fun findByModelNumber(modelNumber: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> {
        if (modelNumber.isBlank()) {
            return Flux.error(InvalidDataException("El número de modelo no puede estar vacío."))
        }
        return productRepository.findByModelNumber(modelNumber, page, size)
    }

    fun findByInferredCategory(category: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> {
        if (category.isBlank()) {
            return Flux.error(InvalidDataException("La categoría no puede estar vacía."))
        }
        return productRepository.findByInferredCategory(category, page, size)
    }

    fun findByInferredPriceRange(
        priceRange: String,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Product> {
        if (priceRange.isBlank()) {
            return Flux.error(InvalidDataException("El rango de precio no puede estar vacío."))
        }
        return productRepository.findByInferredPriceRange(priceRange, page, size)
    }

    fun findByInferredUsageTags(
        usageTags: List<String>,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Product> {
        if (usageTags.isEmpty()) {
            return Flux.error(InvalidDataException("La lista de tags de uso no puede estar vacía."))
        }
        return productRepository.findByInferredUsageTags(usageTags, page, size)
    }

    fun findByRecognitionAccuracyGreaterThan(
        accuracy: BigDecimal,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Product> {
        if (accuracy < BigDecimal.ZERO || accuracy > BigDecimal.ONE) {
            return Flux.error(InvalidDataException("La precisión debe estar entre 0.0 y 1.0."))
        }
        return productRepository.findByRecognitionAccuracyGreaterThan(accuracy, page, size)
    }

    fun findByImageHash(imageHash: String): Mono<Product> {
        if (imageHash.isBlank()) {
            return Mono.error(InvalidDataException("El hash de imagen no puede estar vacío."))
        }
        return productRepository.findByImageHash(imageHash)
            .switchIfEmpty(Mono.error(NotFoundException("No se encontró un producto con el hash de imagen '$imageHash'.")))
    }

    fun findSimilarProducts(
        imageEmbedding: String,
        similarityThreshold: BigDecimal = BigDecimal("0.8"),
        limit: Int = 10
    ): Flux<Product> {
        if (imageEmbedding.isBlank()) {
            return Flux.error(InvalidDataException("El embedding de imagen no puede estar vacío."))
        }
        if (similarityThreshold < BigDecimal.ZERO || similarityThreshold > BigDecimal.ONE) {
            return Flux.error(InvalidDataException("El umbral de similitud debe estar entre 0.0 y 1.0."))
        }
        if (limit <= 0 || limit > 100) {
            return Flux.error(InvalidDataException("El límite debe estar entre 1 y 100."))
        }
        return productRepository.findSimilarProducts(imageEmbedding, similarityThreshold, limit)
    }

    fun findProductsWithRecognitionData(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Product> =
        productRepository.findProductsWithRecognitionData(page, size)

    fun findDuplicateProducts(): Flux<Product> =
        productRepository.findDuplicateProducts()

    /**
     * Identifica o crea un producto a partir de una imagen
     * usando el NUEVO FLUJO de identificación simplificado
     *
     * Flujo:
     * PASO 1: Análisis Vision (extrae todos los campos en UNA llamada GPT-4)
     * PASO 2: Búsqueda por campos exactos (brand + model + category)
     *         - Si encuentra: calcular similitud (60% base + logos + objects)
     *         - Si múltiples: desempatar por tags
     * PASO 3: Si Paso 2 no encuentra nada → buscar por embedding
     * PASO 4: Si aún no encuentra → crear nuevo producto (subir a MinIO aquí)
     *
     * @param request Datos de la imagen y contexto
     * @return ProductIdentificationResult con producto y metadata
     */
    fun identifyOrCreateProduct(request: IdentifyOrCreateProductRequest): Mono<ProductIdentificationResult> {
        val startTime = System.currentTimeMillis()

        logger.info("=== Iniciando identificación individual (NUEVO FLUJO) ===")
        logger.info("Source: ${request.source}, imageFormat: ${request.imageFormat}")

        // 1. Obtener configuración activa de umbrales
        return thresholdConfigRepository.getActiveConfig()
            .flatMap { config ->
                logger.info("Usando configuración v${config.modelVersion}")

                // PASO 1: Análisis Vision (UNA sola llamada GPT-4)
                openAIService.analyzeProductForIdentification(request.imageBytes)
                    .flatMap { visionResult ->
                        logger.info(
                            "✅ PASO 1 completado: brand=${visionResult.brandName}, " +
                                    "model=${visionResult.modelNumber}, category=${visionResult.inferredCategory}"
                        )

                        // PASOS 2-3: Usar método genérico de identificación
                        identifyFromVisionResult(visionResult, config, request.imageBytes)
                            .flatMap { match ->
                                // Producto encontrado
                                handleIdentifiedProductNewFlow(match, config, visionResult, startTime)
                            }
                            .switchIfEmpty(Mono.defer {
                                // PASO 4: No encontrado
                                // REGLA: Solo crear producto nuevo si viene de STOCK o MANUAL
                                // Si viene de SALE → retornar error (no se puede vender producto no registrado)

                                if (request.source == ValidationSource.SALE) {
                                    logger.warn("⚠️ Producto no encontrado y source=SALE → No se puede crear")
                                    val processingTime = System.currentTimeMillis() - startTime

                                    Mono.just(
                                        ProductIdentificationResult(
                                            status = IdentificationStatus.ERROR,
                                            product = Product(
                                                name = visionResult.productName ?: "Producto no identificado",
                                                description = "Producto no encontrado en el sistema",
                                                categoryId = 1
                                            ),
                                            isExisting = false,
                                            confidence = BigDecimal.ZERO,
                                            matchType = null,
                                            similarity = null,
                                            requiresValidation = true,
                                            details = "Producto no encontrado. No se puede registrar venta de productos no existentes.",
                                            alternativeMatches = emptyList(),
                                            processingTimeMs = processingTime,
                                            metadata = mapOf(
                                                "error" to "PRODUCT_NOT_FOUND_FOR_SALE",
                                                "source" to request.source.name,
                                                "vision_brand" to (visionResult.brandName ?: "N/A"),
                                                "vision_model" to (visionResult.modelNumber ?: "N/A"),
                                                "vision_category" to visionResult.inferredCategory,
                                                "message" to "Para vender este producto, primero debe registrarlo en el inventario."
                                            )
                                        )
                                    )
                                } else {
                                    // STOCK o MANUAL → Crear nuevo producto
                                    logger.info("📦 No se encontró producto, creando nuevo (source=${request.source})...")

                                    // Generar embedding para el nuevo producto
                                    openAIService.generateImageEmbedding(request.imageBytes)
                                        .flatMap { embeddingResult ->
                                            handleNewProductNewFlow(
                                                request,
                                                visionResult,
                                                embeddingResult.embedding,
                                                config,
                                                startTime
                                            )
                                        }
                                }
                            })
                    }
            }
            .doOnError { error ->
                logger.error("❌ Error en identificación: ${error.message}", error)
            }
    }

    /**
     * MÉTODO GENÉRICO: Identifica un producto a partir de VisionAnalysisResult
     * Ejecuta PASO 2 (campos exactos) y PASO 3 (embedding) si es necesario.
     * Reutilizable tanto para identificación individual como múltiple.
     *
     * @param visionResult Resultado del análisis Vision
     * @param config Configuración de umbrales
     * @param imageBytes Bytes de la imagen (para generar embedding si es necesario)
     * @return IdentificationMatch si encuentra producto, Mono.empty() si no
     */
    private fun identifyFromVisionResult(
        visionResult: VisionAnalysisResult,
        config: IdentificationThresholdConfig,
        imageBytes: ByteArray
    ): Mono<IdentificationMatch> {

        logger.info("🔍 Identificando producto desde VisionResult...")
        logger.info("  brand=${visionResult.brandName}, model=${visionResult.modelNumber}, category=${visionResult.inferredCategory}")

        // PASO 2: Búsqueda por campos exactos + similitud
        return productIdentificationService.identifyProduct(visionResult)
            .doOnNext { match ->
                logger.info("✅ PASO 2: Encontrado por campos exactos: ${match.product.name}")
            }
            .switchIfEmpty(Mono.defer {
                // PASO 3: Buscar por embedding
                logger.info("📍 PASO 3: Generando embedding y buscando por similitud vectorial...")

                openAIService.generateImageEmbedding(imageBytes)
                    .flatMap { embeddingResult ->
                        productIdentificationService.searchByEmbedding(embeddingResult.embedding, config)
                            .doOnNext { match ->
                                logger.info("✅ PASO 3: Encontrado por embedding: ${match.product.name}")
                            }
                    }
            })
    }

    /**
     * Maneja producto identificado con el NUEVO FLUJO
     */
    private fun handleIdentifiedProductNewFlow(
        match: IdentificationMatch,
        config: IdentificationThresholdConfig,
        visionResult: VisionAnalysisResult,
        startTime: Long
    ): Mono<ProductIdentificationResult> {

        val requiresValidation = match.confidence < config.autoApproveThreshold
        val processingTime = System.currentTimeMillis() - startTime

        logger.info(
            "✅ Producto identificado: ${match.product.name}, " +
                    "confianza: ${(match.confidence * BigDecimal("100")).setScale(1, RoundingMode.HALF_UP)}%, " +
                    "tipo: ${match.matchType}, " +
                    "requiere validación: $requiresValidation"
        )

        return Mono.just(
            ProductIdentificationResult(
                status = if (requiresValidation) IdentificationStatus.PARTIAL_MATCH else IdentificationStatus.IDENTIFIED,
                product = match.product,
                isExisting = true,
                confidence = match.confidence,
                matchType = match.matchType,
                similarity = match.similarity,
                requiresValidation = requiresValidation,
                details = match.details,
                alternativeMatches = emptyList(),
                processingTimeMs = processingTime,
                metadata = mapOf(
                    "match_method" to match.matchType.name,
                    "vision_brand" to (visionResult.brandName ?: "N/A"),
                    "vision_model" to (visionResult.modelNumber ?: "N/A"),
                    "vision_category" to visionResult.inferredCategory,
                    "threshold_config_version" to config.modelVersion,
                    "auto_approve_threshold" to config.autoApproveThreshold
                ) + (match.metadata)
            )
        )
    }

    /**
     * Maneja la creación de nuevo producto con el NUEVO FLUJO
     * NOTA: Aquí se sube la imagen a MinIO (solo cuando se crea producto nuevo)
     */
    private fun handleNewProductNewFlow(
        request: IdentifyOrCreateProductRequest,
        visionResult: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.VisionAnalysisResult,
        imageEmbedding: String,
        config: IdentificationThresholdConfig,
        startTime: Long
    ): Mono<ProductIdentificationResult> {

        logger.info("📦 Creando nuevo producto...")
        logger.info("  Nombre: ${request.name ?: visionResult.productName ?: visionResult.brandName ?: "Producto sin nombre"}")

        // Subir imagen a MinIO (solo para productos nuevos)
        return fileStorageService.uploadProductImage(
            imageBytes = request.imageBytes,
            imageFormat = request.imageFormat
        ).flatMap { imageUrl ->
            logger.info("✅ Imagen subida a MinIO: $imageUrl")

            // Crear producto con datos del Vision Analysis
            val newProduct = Product(
                name = request.name ?: visionResult.productName ?: visionResult.brandName ?: "Producto sin nombre",
                description = request.description ?: visionResult.productDescription ?: "Sin descripción",
                productImage = request.imageBytes,
                imageUrl = imageUrl,
                stockQuantity = request.stockQuantity ?: 0,
                expirationDate = request.expirationDate?.let { LocalDate.parse(it) },
                categoryId = request.categoryId ?: 1L,
                createdAt = LocalDateTime.now(),

                // Campos de embedding
                imageEmbedding = imageEmbedding,
                embeddingModel = "text-embedding-3-small",
                imageUpdatedAt = LocalDateTime.now(),
                embeddingConfidence = BigDecimal("0.95"),
                similarityThreshold = BigDecimal("0.75"),

                // Campos del Vision Analysis
                brandName = visionResult.brandName,
                modelNumber = visionResult.modelNumber,
                dominantColors = if (visionResult.dominantColors.isNotEmpty()) {
                    visionResult.dominantColors.joinToString(", ")
                } else null,
                logoDetection = if (visionResult.detectedLogos.isNotEmpty()) {
                    """{"timestamp": "${LocalDateTime.now()}", "confidence": 0.9, "detected_logos": ["${
                        visionResult.detectedLogos.joinToString(
                            "\", \""
                        )
                    }"]}"""
                } else null,
                objectDetection = if (visionResult.detectedObjects.isNotEmpty()) {
                    """{"timestamp": "${LocalDateTime.now()}", "confidence": 0.85, "detected_objects": ["${
                        visionResult.detectedObjects.joinToString(
                            "\", \""
                        )
                    }"]}"""
                } else null,
                recognitionAccuracy = BigDecimal("0.90"),
                lastRecognitionAt = LocalDateTime.now(),
                recognitionCount = 1,

                // Campos inferidos
                inferredCategory = visionResult.inferredCategory,
                inferredUsageTags = visionResult.inferredUsageTags,
                imageTags = visionResult.imageTags
            )

            productRepository.save(newProduct)
                .map { savedProduct ->
                    val processingTime = System.currentTimeMillis() - startTime

                    logger.info("✅ Nuevo producto creado: ID ${savedProduct.id}, nombre: ${savedProduct.name}")

                    ProductIdentificationResult(
                        status = IdentificationStatus.NEW_PRODUCT_CREATED,
                        product = savedProduct,
                        isExisting = false,
                        confidence = BigDecimal.ZERO,
                        matchType = null,
                        similarity = null,
                        requiresValidation = false,
                        details = "Nuevo producto creado con análisis Vision",
                        alternativeMatches = emptyList(),
                        processingTimeMs = processingTime,
                        metadata = mapOf(
                            "image_url" to imageUrl,
                            "vision_brand" to (visionResult.brandName ?: "N/A"),
                            "vision_model" to (visionResult.modelNumber ?: "N/A"),
                            "vision_category" to visionResult.inferredCategory,
                            "threshold_config_version" to config.modelVersion,
                            "detected_logos" to visionResult.detectedLogos,
                            "detected_objects" to visionResult.detectedObjects
                        )
                    )
                }
        }
    }

    /**
     * Detecta e identifica múltiples productos en una sola imagen usando GPT-4 Vision
     *
     * NUEVO FLUJO REFACTORIZADO:
     * 1. PASO 1: GPT-4 Vision detecta N productos → List<VisionAnalysisResult>
     * 2. Para cada VisionAnalysisResult:
     *    - Usar método genérico identifyFromVisionResult() (PASOS 2-3)
     *    - Si no encuentra, crear producto temporal (no se guarda en BD)
     * 3. Agrupar productos iguales y calcular cantidades
     * 4. Auto-confirmar productos con confianza >= 60%
     *
     * VENTAJA: Reutiliza el mismo flujo de identificación individual.
     *
     * @param request Datos de la imagen y configuración
     * @return MultipleProductDetectionResult con productos agrupados
     */
    fun identifyMultipleProducts(request: MultipleProductDetectionRequest): Mono<MultipleProductDetectionResult> {
        val startTime = System.currentTimeMillis()

        logger.info("=== Iniciando detección múltiple (NUEVO FLUJO REFACTORIZADO) ===")
        logger.info("Source: ${request.source}, groupByProduct: ${request.groupByProduct}")

        val imageBytes = Base64.getDecoder().decode(request.imageBase64)

        // 1. Obtener configuración activa
        return thresholdConfigRepository.getActiveConfig()
            .flatMap { config ->
                logger.info("Usando configuración v${config.modelVersion}")

                // PASO 1: Detectar productos con GPT-4 Vision (retorna List<VisionAnalysisResult>)
                openAIService.detectMultipleProductsForIdentification(imageBytes)
                    .flatMap { visionResults ->
                        logger.info("📦 GPT-4 detectó ${visionResults.size} productos")

                        if (visionResults.isEmpty()) {
                            val processingTime = System.currentTimeMillis() - startTime
                            return@flatMap Mono.just(
                                MultipleProductDetectionResult(
                                    status = IdentificationStatus.ERROR,
                                    productGroups = emptyList(),
                                    totalDetections = 0,
                                    uniqueProducts = 0,
                                    requiresValidation = false,
                                    processingTimeMs = processingTime,
                                    metadata = mapOf(
                                        "message" to "No se detectaron productos en la imagen",
                                        "detection_method" to "GPT-4 Vision (nuevo flujo)"
                                    )
                                )
                            )
                        }

                        // PASOS 2-3: Para cada VisionAnalysisResult, usar método genérico
                        Flux.fromIterable(visionResults.mapIndexed { index, vr -> Pair(index, vr) })
                            .flatMap { (index, visionResult) ->
                                processVisionResultForMultiple(
                                    visionResult = visionResult,
                                    objectIndex = index,
                                    config = config,
                                    imageBytes = imageBytes
                                )
                            }
                            .collectList()
                            .map { matches ->
                                logger.info("Procesados ${matches.size} matches de ${visionResults.size} productos detectados")

                                // Agrupar por producto ID (si se solicita)
                                val productGroups = if (request.groupByProduct) {
                                    groupDetectedProductMatches(matches)
                                } else {
                                    matches.map { match ->
                                        DetectedProductGroup(
                                            product = match.product,
                                            quantity = 1,
                                            averageConfidence = match.combinedConfidence,
                                            detections = listOf(match),
                                            isConfirmed = match.combinedConfidence >= BigDecimal("0.6")
                                        )
                                    }
                                }

                                // Aplicar filtro de confianza mínima si se especificó
                                val filteredGroups = if (request.minConfidence != null) {
                                    productGroups.filter { it.averageConfidence >= request.minConfidence }
                                } else {
                                    productGroups
                                }

                                val processingTime = System.currentTimeMillis() - startTime

                                logger.info("✅ Detección múltiple completada:")
                                logger.info("  - Total detecciones: ${visionResults.size}")
                                logger.info("  - Matches procesados: ${matches.size}")
                                logger.info("  - Grupos de productos: ${filteredGroups.size}")
                                logger.info("  - Tiempo: ${processingTime}ms")

                                MultipleProductDetectionResult(
                                    status = if (filteredGroups.isEmpty()) {
                                        IdentificationStatus.ERROR
                                    } else {
                                        IdentificationStatus.IDENTIFIED
                                    },
                                    productGroups = filteredGroups,
                                    totalDetections = visionResults.size,
                                    uniqueProducts = filteredGroups.size,
                                    requiresValidation = filteredGroups.any { !it.isConfirmed },
                                    processingTimeMs = processingTime,
                                    metadata = mapOf(
                                        "total_detections" to visionResults.size,
                                        "successful_matches" to matches.size,
                                        "groups_count" to filteredGroups.size,
                                        "grouped_by_product" to request.groupByProduct,
                                        "threshold_config_version" to config.modelVersion,
                                        "detection_method" to "GPT-4 Vision (nuevo flujo)"
                                    )
                                )
                            }
                    }
            }
            .doOnError { error ->
                logger.error("❌ Error en detección múltiple: ${error.message}", error)
            }
    }

    /**
     * Procesa un VisionAnalysisResult para detección múltiple:
     * 1. Si tiene bounding box: recortar imagen y generar embedding individual
     * 2. Buscar por campos exactos (PASO 2)
     * 3. Si no encuentra, buscar por embedding del recorte (PASO 3)
     * 4. Si aún no encuentra, crear producto temporal
     *
     * NUEVO ENFOQUE: Ahora usamos recortes de imagen para embeddings individuales
     * - Cada producto detectado se recorta de la imagen original
     * - Se genera un embedding específico del recorte (no de la imagen completa)
     * - Esto permite identificación por embedding sin conflictos entre productos
     */
    private fun processVisionResultForMultiple(
        visionResult: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.VisionAnalysisResult,
        objectIndex: Int,
        config: IdentificationThresholdConfig,
        imageBytes: ByteArray
    ): Mono<DetectedProductMatch> {

        logger.info("  Procesando producto #$objectIndex: ${visionResult.productName ?: visionResult.brandName ?: "Desconocido"}")

        // PASO 1: Recortar imagen si tenemos bounding box
        val croppedImageMono: Mono<ByteArray> = if (visionResult.boundingBox != null) {
            logger.debug("    📐 Recortando imagen: bbox=${visionResult.boundingBox}")
            Mono.fromCallable {
                openAIService.cropImage(imageBytes, visionResult.boundingBox)
            }
        } else {
            logger.debug("    ⚠️ Sin bounding box, usando imagen completa")
            Mono.just(imageBytes)
        }

        // PASO 2: Buscar por campos exactos
        return croppedImageMono.flatMap { croppedBytes ->
            productIdentificationService.identifyProduct(visionResult)
                .map { match ->
                    // Producto encontrado en BD por campos exactos
                    logger.info("    ✅ Identificado por campos: ${match.product.name} (${(match.confidence * BigDecimal("100")).toInt()}%)")

                    DetectedProductMatch(
                        product = match.product,
                        boundingBox = visionResult.boundingBox?.let {
                            BoundingBox(it.x, it.y, it.width, it.height)
                        } ?: BoundingBox(0.0, 0.0, 1.0, 1.0),
                        detectionConfidence = match.confidence,
                        identificationConfidence = match.confidence,
                        combinedConfidence = match.confidence,
                        matchType = match.matchType.name,
                        similarity = match.similarity,
                        alternativeMatches = emptyList(),
                        objectIndex = objectIndex
                    )
                }
                .switchIfEmpty(Mono.defer {
                    // PASO 3: No encontrado por campos exactos → Buscar por embedding del RECORTE
                    if (visionResult.boundingBox != null) {
                        logger.info("    🔍 Generando embedding del recorte para búsqueda...")

                        openAIService.generateImageEmbedding(croppedBytes)
                            .flatMap { embeddingResult ->
                                productIdentificationService.searchByEmbedding(embeddingResult.embedding, config)
                                    .map { match ->
                                        logger.info("    ✅ Identificado por embedding: ${match.product.name} (${(match.confidence * BigDecimal("100")).toInt()}%)")

                                        DetectedProductMatch(
                                            product = match.product,
                                            boundingBox = BoundingBox(
                                                visionResult.boundingBox.x,
                                                visionResult.boundingBox.y,
                                                visionResult.boundingBox.width,
                                                visionResult.boundingBox.height
                                            ),
                                            detectionConfidence = match.confidence,
                                            identificationConfidence = match.confidence,
                                            combinedConfidence = match.confidence,
                                            matchType = match.matchType.name,
                                            similarity = match.similarity,
                                            alternativeMatches = emptyList(),
                                            objectIndex = objectIndex
                                        )
                                    }
                            }
                            .switchIfEmpty(createTemporaryProductMatch(visionResult, objectIndex))
                    } else {
                        // Sin bounding box, crear temporal directamente
                        logger.info("    ⚠️ Sin bbox, no se puede generar embedding individual")
                        createTemporaryProductMatch(visionResult, objectIndex)
                    }
                })
        }
    }

    /**
     * Crea un DetectedProductMatch temporal cuando no se puede identificar el producto
     */
    private fun createTemporaryProductMatch(
        visionResult: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.VisionAnalysisResult,
        objectIndex: Int
    ): Mono<DetectedProductMatch> {
        logger.info("    ⚠️ No identificado, creando producto temporal")

        val temporaryProduct = Product(
            id = -(objectIndex + 1).toLong(), // ID negativo = temporal
            name = visionResult.productName ?: visionResult.brandName ?: "Producto #${objectIndex + 1}",
            description = visionResult.productDescription ?: "Producto detectado por Vision",
            categoryId = 1,
            brandName = visionResult.brandName,
            modelNumber = visionResult.modelNumber,
            inferredCategory = visionResult.inferredCategory,
            inferredUsageTags = visionResult.inferredUsageTags,
            imageTags = visionResult.imageTags,
            recognitionAccuracy = BigDecimal("0.50") // Confianza baja por ser temporal
        )

        return Mono.just(
            DetectedProductMatch(
                product = temporaryProduct,
                boundingBox = visionResult.boundingBox?.let {
                    BoundingBox(it.x, it.y, it.width, it.height)
                } ?: BoundingBox(0.0, 0.0, 1.0, 1.0),
                detectionConfidence = BigDecimal("0.50"),
                identificationConfidence = BigDecimal("0.50"),
                combinedConfidence = BigDecimal("0.50"),
                matchType = "TEMPORARY",
                similarity = null,
                alternativeMatches = emptyList(),
                objectIndex = objectIndex
            )
        )
    }

    /**
     * Agrupa DetectedProductMatch por producto ID y calcula cantidades
     */
    private fun groupDetectedProductMatches(matches: List<DetectedProductMatch>): List<DetectedProductGroup> {
        return matches
            .groupBy { it.product.id }
            .map { (_, detections) ->
                val product = detections.first().product
                val quantity = detections.size

                val averageConfidence = detections
                    .map { it.combinedConfidence }
                    .fold(BigDecimal.ZERO) { acc, conf -> acc + conf }
                    .divide(BigDecimal(quantity), 4, RoundingMode.HALF_UP)

                val isConfirmed = averageConfidence >= BigDecimal("0.6")

                logger.info("  Grupo: ${product.name} × $quantity (confianza: ${(averageConfidence * BigDecimal("100")).toInt()}%)")

                DetectedProductGroup(
                    product = product,
                    quantity = quantity,
                    averageConfidence = averageConfidence,
                    detections = detections,
                    isConfirmed = isConfirmed
                )
            }
            .sortedByDescending { it.averageConfidence }
    }

    // ==================== MÉTODOS LEGACY (para compatibilidad) ====================

    /**
     * @deprecated Usar processVisionResultForMultiple en su lugar
     */
    private fun processGPT4DetectedProduct(
        detectedProduct: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.DetectedProductInfo,
        objectIndex: Int,
        config: IdentificationThresholdConfig
    ): Mono<DetectedProductMatch> {

        logger.warn("⚠️ Usando método legacy processGPT4DetectedProduct")

        val boundingBox = detectedProduct.getBoundingBox()

        // Buscar primero por marca si está disponible
        val searchMono = if (!detectedProduct.marca.isNullOrBlank()) {
            productRepository.findByBrandName(detectedProduct.marca, 0, 5)
                .filter { product ->
                    if (!detectedProduct.modelo.isNullOrBlank()) {
                        product.modelNumber?.contains(detectedProduct.modelo, ignoreCase = true) == true ||
                                product.name.contains(detectedProduct.modelo, ignoreCase = true)
                    } else {
                        true
                    }
                }
                .collectList()
                .flatMap { products ->
                    if (products.isNotEmpty()) {
                        Mono.just(products.first())
                    } else {
                        searchByCategory(detectedProduct)
                    }
                }
        } else {
            searchByCategory(detectedProduct)
        }

        return searchMono.map { product ->
            val identificationConfidence = BigDecimal(detectedProduct.confianza.toString())

            DetectedProductMatch(
                product = product,
                boundingBox = BoundingBox(
                    x = boundingBox.x,
                    y = boundingBox.y,
                    width = boundingBox.width,
                    height = boundingBox.height
                ),
                detectionConfidence = BigDecimal(detectedProduct.confianza.toString()),
                identificationConfidence = identificationConfidence,
                combinedConfidence = identificationConfidence,
                matchType = if (!detectedProduct.marca.isNullOrBlank()) {
                    MatchType.BRAND_MODEL.name
                } else {
                    MatchType.TAG_CATEGORY.name
                },
                similarity = null,
                alternativeMatches = emptyList(),
                objectIndex = objectIndex
            )
        }.switchIfEmpty(
            // Si no se encontró, crear producto temporal
            createTemporaryProductFromGPT4Detection(detectedProduct, objectIndex, boundingBox)
        )
    }

    /**
     * Busca producto por categoría inferida
     */
    private fun searchByCategory(
        detectedProduct: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.DetectedProductInfo
    ): Mono<Product> {
        return productRepository.findByInferredCategory(detectedProduct.categoria, 0, 10)
            .filter { product ->
                // Filtrar por nombre similar
                val searchTerms = detectedProduct.nombre.lowercase().split(" ")
                searchTerms.any { term ->
                    term.length > 2 && (
                            product.name.lowercase().contains(term) ||
                                    product.description?.lowercase()?.contains(term) == true
                            )
                }
            }
            .next()
            .doOnNext { product ->
                logger.info("  ✅ Encontrado por categoría: ${product.name}")
            }
    }

    /**
     * Crea un producto temporal a partir de la detección de GPT-4
     * (para mostrar al usuario, no se guarda en BD automáticamente)
     */
    private fun createTemporaryProductFromGPT4Detection(
        detectedProduct: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.DetectedProductInfo,
        objectIndex: Int,
        boundingBox: com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.BoundingBoxCoordinates
    ): Mono<DetectedProductMatch> {
        logger.info("  ⚠️ Producto no encontrado en BD, creando temporal: ${detectedProduct.nombre}")

        // Crear producto temporal (ID negativo para indicar que es nuevo)
        val temporaryProduct = Product(
            id = -(objectIndex + 1).toLong(),
            name = detectedProduct.nombre,
            description = detectedProduct.descripcion,
            categoryId = 1, // Categoría por defecto
            brandName = detectedProduct.marca,
            modelNumber = detectedProduct.modelo,
            inferredCategory = detectedProduct.categoria,
            recognitionAccuracy = BigDecimal(detectedProduct.confianza.toString())
        )

        return Mono.just(
            DetectedProductMatch(
                product = temporaryProduct,
                boundingBox = BoundingBox(
                    x = boundingBox.x,
                    y = boundingBox.y,
                    width = boundingBox.width,
                    height = boundingBox.height
                ),
                detectionConfidence = BigDecimal(detectedProduct.confianza.toString()),
                identificationConfidence = BigDecimal("0.5"), // Confianza baja por ser producto nuevo
                combinedConfidence = BigDecimal(detectedProduct.confianza.toString())
                    .multiply(BigDecimal("0.5")),
                matchType = MatchType.TAG_CATEGORY.name,
                similarity = null,
                alternativeMatches = emptyList(),
                objectIndex = objectIndex
            )
        )
    }

    /**
     * Agrupa productos por ID y calcula cantidades
     */
    private fun groupByProduct(matches: List<DetectedProductMatch>): List<DetectedProductGroup> {
        return matches
            .groupBy { it.product.id }
            .map { (productId, detections) ->
                val product = detections.first().product
                val quantity = detections.size

                // Calcular confianza promedio
                val averageConfidence = detections
                    .map { it.combinedConfidence }
                    .fold(BigDecimal.ZERO) { acc, conf -> acc + conf }
                    .divide(BigDecimal(quantity), 4, RoundingMode.HALF_UP)

                // Auto-confirmar si confianza >= 60%
                val isConfirmed = averageConfidence >= BigDecimal("0.6")

                logger.info(
                    "Producto agrupado: ${product.name} × $quantity " +
                            "(confianza promedio: $averageConfidence, auto-confirmado: $isConfirmed)"
                )

                DetectedProductGroup(
                    product = product,
                    quantity = quantity,
                    averageConfidence = averageConfidence,
                    detections = detections,
                    isConfirmed = isConfirmed
                )
            }
            .sortedByDescending { it.averageConfidence } // Ordenar por confianza
    }
}