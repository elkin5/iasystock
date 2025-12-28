package com.co.kinsoft.api.iasy_stock_api.domain.usecase.saleitem

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.gateway.SaleItemRepository
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.productstock.ProductStockUseCase
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal

class SaleItemUseCase(
    private val saleItemRepository: SaleItemRepository,
    private val productStockUseCase: ProductStockUseCase
) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<SaleItem> =
        saleItemRepository.findAll(page, size)

    fun findById(id: Long): Mono<SaleItem> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return saleItemRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("El detalle de venta con ID $id no existe.")))
    }

    fun create(saleItem: SaleItem): Mono<SaleItem> {
        return Mono.fromCallable {
            SaleItemValidator.validate(saleItem)
            saleItem
        }.flatMap { validatedSaleItem ->
            saleItemRepository.save(validatedSaleItem)
                .flatMap { savedSaleItem ->
                    // Decrementar el stock del producto automáticamente
                    productStockUseCase.decrementProductStock(savedSaleItem.productId, savedSaleItem.quantity)
                        .thenReturn(savedSaleItem)
                }
        }
    }

    fun update(id: Long, saleItem: SaleItem): Mono<SaleItem> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            SaleItemValidator.validate(saleItem)
            saleItem
        }.flatMap { validatedSaleItem ->
            saleItemRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("El detalle de venta con ID $id no existe.")))
                .flatMap { existingSaleItem ->
                    val updatedSaleItem = existingSaleItem.copy(
                        saleId = validatedSaleItem.saleId,
                        productId = validatedSaleItem.productId,
                        quantity = validatedSaleItem.quantity,
                        unitPrice = validatedSaleItem.unitPrice,
                        totalPrice = validatedSaleItem.totalPrice
                    )
                    
                    saleItemRepository.save(updatedSaleItem)
                        .flatMap { savedSaleItem ->
                            // Calcular la diferencia en cantidad para actualizar el stock del producto
                            val quantityDifference = existingSaleItem.quantity - savedSaleItem.quantity
                            
                            // Solo actualizar si hay diferencia en la cantidad
                            if (quantityDifference != 0) {
                                productStockUseCase.updateProductStock(savedSaleItem.productId, quantityDifference)
                                    .thenReturn(savedSaleItem)
                            } else {
                                Mono.just(savedSaleItem)
                            }
                        }
                }
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return saleItemRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: el detalle de venta con ID $id no existe.")))
            .flatMap { saleItemToDelete ->
                // Restaurar el stock del producto antes de eliminar el SaleItem
                productStockUseCase.incrementProductStock(saleItemToDelete.productId, saleItemToDelete.quantity)
                    .then(saleItemRepository.deleteById(id))
            }
    }

    fun findBySaleId(saleId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<SaleItem> {
        if (saleId <= 0) {
            return Flux.error(InvalidDataException("El ID de la venta debe ser un valor positivo."))
        }
        return saleItemRepository.findBySaleId(saleId, page, size)
    }

    fun findByProductId(productId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<SaleItem> {
        if (productId <= 0) {
            return Flux.error(InvalidDataException("El ID del producto debe ser un valor positivo."))
        }
        return saleItemRepository.findByProductId(productId, page, size)
    }

    fun calculateTotalBySaleId(saleId: Long): Mono<BigDecimal> {
        if (saleId <= 0) {
            return Mono.error(InvalidDataException("El ID de la venta debe ser un valor positivo."))
        }
        return saleItemRepository.findBySaleId(saleId, 0, Int.MAX_VALUE)
            .map { it.totalPrice }
            .reduce(BigDecimal.ZERO) { acc, totalPrice -> acc.add(totalPrice) }
    }
}