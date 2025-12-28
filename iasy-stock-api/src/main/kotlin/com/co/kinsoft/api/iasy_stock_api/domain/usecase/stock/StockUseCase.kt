package com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock
import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.gateway.StockRepository
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.productstock.ProductStockUseCase
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDate

class StockUseCase(
    private val stockRepository: StockRepository,
    private val productStockUseCase: ProductStockUseCase
) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> =
        stockRepository.findAll(page, size)

    fun findById(id: Long): Mono<Stock> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return stockRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("El registro de stock con ID $id no existe.")))
    }

    fun create(stock: Stock): Mono<Stock> {
        return Mono.fromCallable {
            StockValidator.validate(stock)
            stock
        }.flatMap { validatedStock ->
            stockRepository.save(validatedStock)
                .flatMap { savedStock ->
                    // Actualizar el stock del producto automáticamente
                    productStockUseCase.updateProductStock(savedStock.productId, savedStock.quantity)
                        .thenReturn(savedStock)
                }
        }
    }

    fun update(id: Long, stock: Stock): Mono<Stock> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            StockValidator.validate(stock)
            stock
        }.flatMap { validatedStock ->
            stockRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("El registro de stock con ID $id no existe.")))
                .flatMap { existingStock ->
                    val updatedStock = existingStock.copy(
                        quantity = validatedStock.quantity,
                        entryPrice = validatedStock.entryPrice,
                        salePrice = validatedStock.salePrice,
                        productId = validatedStock.productId,
                        userId = validatedStock.userId,
                        warehouseId = validatedStock.warehouseId,
                        personId = validatedStock.personId,
                        entryDate = validatedStock.entryDate
                    )
                    
                    stockRepository.save(updatedStock)
                        .flatMap { savedStock ->
                            // Calcular la diferencia en cantidad para actualizar el stock del producto
                            val quantityDifference = savedStock.quantity - existingStock.quantity
                            
                            // Solo actualizar si hay diferencia en la cantidad
                            if (quantityDifference != 0) {
                                productStockUseCase.updateProductStock(savedStock.productId, quantityDifference)
                                    .thenReturn(savedStock)
                            } else {
                                Mono.just(savedStock)
                            }
                        }
                }
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return stockRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: el registro de stock con ID $id no existe.")))
            .flatMap { stockToDelete ->
                // Restaurar el stock del producto antes de eliminar el registro
                productStockUseCase.updateProductStock(stockToDelete.productId, -stockToDelete.quantity)
                    .then(stockRepository.deleteById(id))
            }
    }

    fun findByProductId(productId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> {
        if (productId <= 0) {
            return Flux.error(InvalidDataException("El ID del producto debe ser un valor positivo."))
        }
        return stockRepository.findByProductId(productId, page, size)
    }

    fun findByWarehouseId(warehouseId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> {
        if (warehouseId <= 0) {
            return Flux.error(InvalidDataException("El ID del almacén debe ser un valor positivo."))
        }
        return stockRepository.findByWarehouseId(warehouseId, page, size)
    }

    fun findByUserId(userId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> {
        if (userId <= 0) {
            return Flux.error(InvalidDataException("El ID del usuario debe ser un valor positivo."))
        }
        return stockRepository.findByUserId(userId, page, size)
    }

    fun findByEntryDate(entryDate: LocalDate, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> =
        stockRepository.findByEntryDate(entryDate, page, size)

    fun findByQuantityGreaterThan(quantity: Int, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> {
        if (quantity < 0) {
            return Flux.error(InvalidDataException("La cantidad debe ser cero o mayor."))
        }
        return stockRepository.findByQuantityGreaterThan(quantity, page, size)
    }

    fun findByPersonId(personId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Stock> {
        if (personId <= 0) {
            return Flux.error(InvalidDataException("El ID del proveedor debe ser un valor positivo."))
        }
        return stockRepository.findByPersonId(personId, page, size)
    }
}