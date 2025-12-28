package com.co.kinsoft.api.iasy_stock_api.domain.model.sale.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

interface SaleRepository {
    fun findAll(page: Int, size: Int): Flux<Sale>
    fun findById(id: Long): Mono<Sale>
    fun save(sale: Sale): Mono<Sale>
    fun deleteById(id: Long): Mono<Void>

    // Métodos adicionales
    fun findByUserId(userId: Long, page: Int, size: Int): Flux<Sale>
    fun findByPersonId(personId: Long, page: Int, size: Int): Flux<Sale>
    fun findBySaleDate(saleDate: LocalDate, page: Int, size: Int): Flux<Sale>
    fun findByTotalAmountGreaterThan(amount: BigDecimal, page: Int, size: Int): Flux<Sale>
    fun findByState(state: String, page: Int, size: Int): Flux<Sale>
}