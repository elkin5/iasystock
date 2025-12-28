package com.co.kinsoft.api.iasy_stock_api.domain.model.stock.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDate

interface StockRepository {
    fun findAll(page: Int, size: Int): Flux<Stock>
    fun findById(id: Long): Mono<Stock>
    fun save(stock: Stock): Mono<Stock>
    fun deleteById(id: Long): Mono<Void>
    fun findByProductId(productId: Long, page: Int, size: Int): Flux<Stock>
    fun findByWarehouseId(warehouseId: Long, page: Int, size: Int): Flux<Stock>
    fun findByUserId(userId: Long, page: Int, size: Int): Flux<Stock>
    fun findByEntryDate(entryDate: LocalDate, page: Int, size: Int): Flux<Stock>
    fun findByQuantityGreaterThan(quantity: Int, page: Int, size: Int): Flux<Stock>
    fun findByPersonId(personId: Long, page: Int, size: Int): Flux<Stock>
}