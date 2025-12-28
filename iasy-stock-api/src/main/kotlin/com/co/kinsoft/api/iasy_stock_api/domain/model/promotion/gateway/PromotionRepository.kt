package com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.Promotion
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

interface PromotionRepository {
    fun findAll(page: Int, size: Int): Flux<Promotion>
    fun findById(id: Long): Mono<Promotion>
    fun save(promotion: Promotion): Mono<Promotion>
    fun deleteById(id: Long): Mono<Void>
    fun findByDescription(description: String, page: Int, size: Int): Flux<Promotion>
    fun findByDiscountRateGreaterThan(rate: BigDecimal, page: Int, size: Int): Flux<Promotion>
    fun findByStartDateBeforeAndEndDateAfter(
        startDate: LocalDate, endDate: LocalDate, page: Int, size: Int
    ): Flux<Promotion>

    fun findByProductId(productId: Long?, page: Int, size: Int): Flux<Promotion>
    fun findByCategoryId(categoryId: Long, page: Int, size: Int): Flux<Promotion>
}