package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.stock

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import java.time.LocalDate

interface StockDAORepository : ReactiveCrudRepository<StockDAO, Long> {
    fun findByProductId(productId: Long): Flux<StockDAO>
    fun findByWarehouseId(warehouseId: Long): Flux<StockDAO>
    fun findByUserId(userId: Long): Flux<StockDAO>
    fun findByEntryDate(entryDate: LocalDate): Flux<StockDAO>
    fun findByQuantityGreaterThan(quantity: Int): Flux<StockDAO>
    fun findByPersonId(personId: Long): Flux<StockDAO>
}