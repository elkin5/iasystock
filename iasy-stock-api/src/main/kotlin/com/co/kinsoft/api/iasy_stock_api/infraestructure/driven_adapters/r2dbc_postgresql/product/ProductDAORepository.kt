package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.product

import org.springframework.data.r2dbc.repository.Modifying
import org.springframework.data.r2dbc.repository.Query
import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

interface ProductDAORepository : ReactiveCrudRepository<ProductDAO, Long> {
    // Métodos existentes
    fun findByNameContainingIgnoreCase(name: String): Flux<ProductDAO>
    fun findByCategoryId(categoryId: Long): Flux<ProductDAO>
    fun findByStockQuantityGreaterThan(quantity: Int): Flux<ProductDAO>
    fun findByExpirationDateBefore(expirationDate: LocalDate): Flux<ProductDAO>

    // Métodos de búsqueda por reconocimiento automático
    fun findByBarcodeData(barcodeData: String): Mono<ProductDAO>
    fun findByBrandNameContainingIgnoreCase(brandName: String): Flux<ProductDAO>
    fun findByModelNumberContainingIgnoreCase(modelNumber: String): Flux<ProductDAO>
    fun findByInferredCategoryContainingIgnoreCase(category: String): Flux<ProductDAO>
    fun findByInferredPriceRange(priceRange: String): Flux<ProductDAO>
    fun findByInferredUsageTagsContaining(usageTag: String): Flux<ProductDAO>
    fun findByRecognitionAccuracyGreaterThan(accuracy: BigDecimal): Flux<ProductDAO>
    fun findByImageHash(imageHash: String): Mono<ProductDAO>
    fun findByImageEmbeddingIsNotNull(): Flux<ProductDAO>
    fun findByBarcodeDataIsNotNull(): Flux<ProductDAO>
    fun findByBrandNameIsNotNull(): Flux<ProductDAO>
    fun findByObjectDetectionIsNotNull(): Flux<ProductDAO>

    @Modifying
    @Query("UPDATE schmain.Product SET stock_quantity = :newStockQuantity WHERE product_id = :productId")
    fun updateStockQuantity(productId: Long, newStockQuantity: Int): Mono<Int>
}