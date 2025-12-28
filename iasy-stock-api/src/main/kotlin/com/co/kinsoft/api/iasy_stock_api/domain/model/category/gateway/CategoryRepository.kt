package com.co.kinsoft.api.iasy_stock_api.domain.model.category.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.category.Category
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface CategoryRepository {
    fun findAll(page: Int, size: Int): Flux<Category>
    fun findById(id: Long): Mono<Category>
    fun save(category: Category): Mono<Category>
    fun deleteById(id: Long): Mono<Void>
    fun findByName(name: String, page: Int, size: Int): Flux<Category>
    fun findByNameContaining(name: String, page: Int, size: Int): Flux<Category>
}