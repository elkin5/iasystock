package com.co.kinsoft.api.iasy_stock_api.domain.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.stats.SalesByDateStat
import com.co.kinsoft.api.iasy_stock_api.domain.model.stats.TopProductStat
import reactor.core.publisher.Flux
import java.time.LocalDate

interface StatsRepository {
    fun getSalesByDate(from: LocalDate?, to: LocalDate?): Flux<SalesByDateStat>
    fun getTopProducts(limit: Int = 5): Flux<TopProductStat>
}

