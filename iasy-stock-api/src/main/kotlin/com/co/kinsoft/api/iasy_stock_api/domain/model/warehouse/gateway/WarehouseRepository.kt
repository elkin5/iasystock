package com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.Warehouse
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface WarehouseRepository {
    fun findAll(page: Int, size: Int): Flux<Warehouse>
    fun findById(id: Long): Mono<Warehouse>
    fun save(warehouse: Warehouse): Mono<Warehouse>
    fun deleteById(id: Long): Mono<Void>

    // Métodos adicionales
    fun findByName(name: String, page: Int, size: Int): Flux<Warehouse>
    fun findByNameContaining(name: String, page: Int, size: Int): Flux<Warehouse>
    fun findByLocation(location: String, page: Int, size: Int): Flux<Warehouse>
}