package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.promotion

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import java.math.BigDecimal
import java.time.LocalDate

interface PromotionDAORepository : ReactiveCrudRepository<PromotionDAO, Long> {
    fun findByDescriptionContainingIgnoreCase(description: String): Flux<PromotionDAO>
    fun findByDiscountRateGreaterThan(rate: BigDecimal): Flux<PromotionDAO>
    fun findByStartDateBeforeAndEndDateAfter(startDate: LocalDate, endDate: LocalDate): Flux<PromotionDAO>
    fun findByProductId(productId: Long?): Flux<PromotionDAO>
    fun findByCategoryId(categoryId: Long): Flux<PromotionDAO>
}