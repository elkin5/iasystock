package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.sale

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import java.math.BigDecimal
import java.time.LocalDate

interface SaleDAORepository : ReactiveCrudRepository<SaleDAO, Long> {
    fun findByUserId(userId: Long): Flux<SaleDAO>
    fun findByPersonId(personId: Long): Flux<SaleDAO>
    fun findBySaleDate(saleDate: LocalDate): Flux<SaleDAO>
    fun findByTotalAmountGreaterThan(amount: BigDecimal): Flux<SaleDAO>
    fun findByState(state: String): Flux<SaleDAO>
}