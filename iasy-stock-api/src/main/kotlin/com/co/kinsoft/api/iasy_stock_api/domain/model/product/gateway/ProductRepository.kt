package com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

interface ProductRepository {
    fun findAll(page: Int, size: Int): Flux<Product>
    fun findById(id: Long): Mono<Product>
    fun save(product: Product): Mono<Product>
    fun deleteById(id: Long): Mono<Void>

    // Métodos adicionales existentes
    fun findByName(name: String, page: Int, size: Int): Flux<Product>
    fun findByCategoryId(categoryId: Long, page: Int, size: Int): Flux<Product>
    fun findByStockQuantityGreaterThan(quantity: Int, page: Int, size: Int): Flux<Product>
    fun findByExpirationDateBefore(expirationDate: LocalDate, page: Int, size: Int): Flux<Product>

    // Métodos de búsqueda por reconocimiento automático
    fun findByBarcodeData(barcodeData: String): Mono<Product>
    fun findByBrandName(brandName: String, page: Int, size: Int): Flux<Product>
    fun findByModelNumber(modelNumber: String, page: Int, size: Int): Flux<Product>
    fun findByInferredCategory(category: String, page: Int, size: Int): Flux<Product>
    fun findByInferredPriceRange(priceRange: String, page: Int, size: Int): Flux<Product>
    fun findByInferredUsageTags(usageTags: List<String>, page: Int, size: Int): Flux<Product>
    fun findByRecognitionAccuracyGreaterThan(accuracy: BigDecimal, page: Int, size: Int): Flux<Product>
    fun findByImageHash(imageHash: String): Mono<Product>
    fun findSimilarProducts(imageEmbedding: String, similarityThreshold: BigDecimal, limit: Int): Flux<Product>
    fun findProductsWithRecognitionData(page: Int, size: Int): Flux<Product>
    fun findDuplicateProducts(): Flux<Product>
    fun updateStockQuantity(productId: Long, newStockQuantity: Int): Mono<Void>

    /**
     * Busca productos por campos exactos (NUEVO FLUJO DE IDENTIFICACIÓN)
     * Usado en Paso 2: Búsqueda por campos de Vision
     *
     * @param brandName Marca del producto (puede ser null)
     * @param modelNumber Número de modelo (puede ser null)
     * @param inferredCategory Categoría inferida
     * @return Flux de productos que coinciden con los criterios
     */
    fun findByExactFields(
        brandName: String?,
        modelNumber: String?,
        inferredCategory: String
    ): Flux<Product>

    /**
     * Busca un producto por similitud vectorial y retorna solo el más similar
     * Usado en Paso 3: Búsqueda por embedding (sin desambiguación)
     *
     * @param imageEmbedding Embedding de la imagen
     * @param similarityThreshold Umbral mínimo de similitud
     * @return Mono del producto más similar o empty si no hay coincidencias
     */
    fun findMostSimilarProduct(
        imageEmbedding: String,
        similarityThreshold: BigDecimal
    ): Mono<Product>
}