package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.saleitem

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux

interface SaleItemDAORepository : ReactiveCrudRepository<SaleItemDAO, Long> {
    fun findBySaleId(saleId: Long): Flux<SaleItemDAO>
    fun findByProductId(productId: Long): Flux<SaleItemDAO>
}