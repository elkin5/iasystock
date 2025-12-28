package com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface SaleItemRepository {
    fun findAll(page: Int, size: Int): Flux<SaleItem>
    fun findById(id: Long): Mono<SaleItem>
    fun save(saleItem: SaleItem): Mono<SaleItem>
    fun deleteById(id: Long): Mono<Void>

    // Métodos adicionales
    fun findBySaleId(saleId: Long, page: Int, size: Int): Flux<SaleItem>
    fun findByProductId(productId: Long, page: Int, size: Int): Flux<SaleItem>
}