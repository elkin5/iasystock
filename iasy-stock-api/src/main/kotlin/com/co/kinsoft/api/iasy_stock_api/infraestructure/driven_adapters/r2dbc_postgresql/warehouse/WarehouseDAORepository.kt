package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.warehouse

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux

interface WarehouseDAORepository : ReactiveCrudRepository<WarehouseDAO, Long> {
    fun findByName(name: String): Flux<WarehouseDAO>
    fun findByNameContaining(name: String): Flux<WarehouseDAO>
    fun findByLocation(location: String): Flux<WarehouseDAO>
}