package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.product

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

@Repository
class ProductRepositoryAdapter(
    private val productDAORepository: ProductDAORepository,
    private val productDAORepositoryCustom: ProductDAORepositoryCustom,
    private val productMapper: ProductMapper
) : ProductRepository {

    override fun findAll(page: Int, size: Int): Flux<Product> {
        return productDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Product> {
        return productDAORepository.findById(id)
            .map { productMapper.toDomain(it) }
    }

    override fun save(product: Product): Mono<Product> {

        // Formatear el imageEmbedding para que sea compatible con PostgreSQL vector
        if (product.imageEmbedding != null) {
            val embedding = product.imageEmbedding.toString()
            // Si no tiene corchetes, agregarlos
            if (!embedding.startsWith("[") && !embedding.endsWith("]")) {
                product.imageEmbedding = "[$embedding]"
            }
        }

        return productDAORepositoryCustom.insertProductWithEmbedding(product = product)
            .map { productMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return productDAORepository.deleteById(id)
    }

    override fun findByName(name: String, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByNameContainingIgnoreCase(name)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByCategoryId(categoryId: Long, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByCategoryId(categoryId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByStockQuantityGreaterThan(quantity: Int, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByStockQuantityGreaterThan(quantity)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByExpirationDateBefore(expirationDate: LocalDate, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByExpirationDateBefore(expirationDate)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    // Implementación de métodos de búsqueda por reconocimiento automático
    override fun findByBarcodeData(barcodeData: String): Mono<Product> {
        return productDAORepository.findByBarcodeData(barcodeData)
            .map { productMapper.toDomain(it) }
    }

    override fun findByBrandName(brandName: String, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByBrandNameContainingIgnoreCase(brandName)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByModelNumber(modelNumber: String, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByModelNumberContainingIgnoreCase(modelNumber)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByInferredCategory(category: String, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByInferredCategoryContainingIgnoreCase(category)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByInferredPriceRange(priceRange: String, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByInferredPriceRange(priceRange)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByInferredUsageTags(usageTags: List<String>, page: Int, size: Int): Flux<Product> {
        return if (usageTags.isNotEmpty()) {
            Flux.fromIterable(usageTags)
                .flatMap { tag ->
                    productDAORepository.findByInferredUsageTagsContaining(tag)
                }
                .distinct()
                .sort(compareByDescending { it.id })
                .skip((page * size).toLong())
                .take(size.toLong())
                .map { productMapper.toDomain(it) }
        } else {
            Flux.empty()
        }
    }

    override fun findByRecognitionAccuracyGreaterThan(accuracy: BigDecimal, page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByRecognitionAccuracyGreaterThan(accuracy)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findByImageHash(imageHash: String): Mono<Product> {
        return productDAORepository.findByImageHash(imageHash)
            .map { productMapper.toDomain(it) }
    }

    override fun findSimilarProducts(
        imageEmbedding: String,
        similarityThreshold: BigDecimal,
        limit: Int
    ): Flux<Product> {
        return productDAORepositoryCustom.findSimilarProducts(
            imageEmbedding = imageEmbedding,
            similarityThreshold = similarityThreshold,
            limit = limit
        ).map { productMapper.toDomain(it) }
    }

    override fun findProductsWithRecognitionData(page: Int, size: Int): Flux<Product> {
        return productDAORepository.findByImageEmbeddingIsNotNull()
            .mergeWith(productDAORepository.findByBarcodeDataIsNotNull())
            .mergeWith(productDAORepository.findByBrandNameIsNotNull())
            .mergeWith(productDAORepository.findByObjectDetectionIsNotNull())
            .distinct()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { productMapper.toDomain(it) }
    }

    override fun findDuplicateProducts(): Flux<Product> {
        // Esta implementación requerirá una consulta SQL personalizada para detectar duplicados
        // Por ahora retornamos productos con embeddings
        return productDAORepository.findByImageEmbeddingIsNotNull()
            .take(10)
            .map { productMapper.toDomain(it) }
    }
    
    override fun updateStockQuantity(productId: Long, newStockQuantity: Int): Mono<Void> {
        return productDAORepository.updateStockQuantity(productId, newStockQuantity)
            .then()
    }

    override fun findByExactFields(
        brandName: String?,
        modelNumber: String?,
        inferredCategory: String
    ): Flux<Product> {
        return productDAORepositoryCustom.findByExactFields(
            brandName = brandName,
            modelNumber = modelNumber,
            inferredCategory = inferredCategory
        ).map { productMapper.toDomain(it) }
    }

    override fun findMostSimilarProduct(
        imageEmbedding: String,
        similarityThreshold: BigDecimal
    ): Mono<Product> {
        return productDAORepositoryCustom.findMostSimilarProduct(
            imageEmbedding = imageEmbedding,
            similarityThreshold = similarityThreshold
        ).map { productMapper.toDomain(it) }
    }
}