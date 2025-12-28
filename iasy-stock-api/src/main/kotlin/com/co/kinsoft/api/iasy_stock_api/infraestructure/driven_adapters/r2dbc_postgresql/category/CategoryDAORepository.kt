package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.category

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux

interface CategoryDAORepository : ReactiveCrudRepository<CategoryDAO, Long> {
    fun findByName(name: String): Flux<CategoryDAO>
    fun findByNameContainingIgnoreCase(name: String): Flux<CategoryDAO>
}