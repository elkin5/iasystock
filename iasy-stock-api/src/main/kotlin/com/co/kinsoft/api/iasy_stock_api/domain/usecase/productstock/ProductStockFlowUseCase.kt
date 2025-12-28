package com.co.kinsoft.api.iasy_stock_api.domain.usecase.productstock

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.model.productstock.ProductStock
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.product.ProductUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock.StockUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Caso de uso para gestionar la creación y consulta de productos con su historial de stock.
 */
class ProductStockFlowUseCase(
    private val productUseCase: ProductUseCase,
    private val stockUseCase: StockUseCase
) {

    private val logger: Logger = LoggerFactory.getLogger(ProductStockFlowUseCase::class.java)

    /**
     * Registra un producto junto con sus movimientos de stock asociados.
     */
    fun create(productStock: ProductStock): Mono<ProductStock> {
        logger.info("Iniciando registro de producto con stocks asociados")
        return validateProductStock(productStock)
            .flatMap { validated ->
                val productMono = if (validated.product.id > 0) {
                    logger.info("Se usará el producto existente con ID {}", validated.product.id)
                    productUseCase.findById(validated.product.id)
                } else {
                    productUseCase.create(validated.product)
                }

                productMono.flatMap { persistedProduct ->
                    if (persistedProduct.id <= 0) {
                        return@flatMap Mono.error<ProductStock>(InvalidDataException("El producto debe tener un ID válido después de crearse."))
                    }

                    Flux.fromIterable(validated.stocks)
                        .flatMap { stock ->
                            val stockToCreate = stock.copy(productId = persistedProduct.id)
                            stockUseCase.create(stockToCreate)
                        }
                        .collectList()
                        .flatMap { createdStocks ->
                            productUseCase.findById(persistedProduct.id)
                                .defaultIfEmpty(persistedProduct)
                                .map { refreshedProduct ->
                                    ProductStock(
                                        product = refreshedProduct,
                                        stocks = createdStocks
                                    )
                                }
                        }
                }
            }
    }

    /**
     * Obtiene productos con su información de stock de manera paginada.
     */
    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<ProductStock> {
        if (page < 0 || size <= 0) {
            return Flux.error(InvalidDataException("Los parámetros de paginación son inválidos."))
        }

        logger.info("Consultando productos con stock: page={}, size={}", page, size)

        return productUseCase.findAll(page, size)
            .flatMap { product ->
                if (product.id <= 0) {
                    Mono.error(InvalidDataException("El producto consultado no tiene un ID válido."))
                } else {
                    stockUseCase.findByProductId(product.id)
                        .collectList()
                        .map { stocks -> ProductStock(product = product, stocks = stocks) }
                }
            }
            .collectList()
            .map { productStocks ->
                productStocks.sortedByDescending { latestStockTimestamp(it) }
            }
            .flatMapMany { Flux.fromIterable(it) }
    }

    private fun validateProductStock(productStock: ProductStock): Mono<ProductStock> {
        return Mono.fromCallable {
            if (!productStock.product.isValid()) {
                throw InvalidDataException("El producto proporcionado no es válido")
            }

            if (!productStock.hasStocks()) {
                throw InvalidDataException("Debe incluir al menos un registro de stock")
            }

            productStock
        }
    }

    private fun latestStockTimestamp(productStock: ProductStock): LocalDateTime {
        val latestCreated = productStock.stocks
            .mapNotNull { it.createdAt }
            .maxOrNull()

        if (latestCreated != null) {
            return latestCreated
        }

        val latestEntryDate = productStock.stocks
            .mapNotNull { it.entryDate?.atStartOfDay() }
            .maxOrNull()

        return latestEntryDate ?: productStock.product.createdAt
    }
}
