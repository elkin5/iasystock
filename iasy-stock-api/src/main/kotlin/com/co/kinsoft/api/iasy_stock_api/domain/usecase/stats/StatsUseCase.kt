package com.co.kinsoft.api.iasy_stock_api.domain.usecase.stats

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.gateway.StatsRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.stats.SalesByDateStat
import com.co.kinsoft.api.iasy_stock_api.domain.model.stats.TopProductStat
import reactor.core.publisher.Flux
import java.time.LocalDate

class StatsUseCase(private val statsRepository: StatsRepository) {

    fun salesByDate(from: LocalDate?, to: LocalDate?): Flux<SalesByDateStat> {
        if (from != null && to != null && from.isAfter(to)) {
            return Flux.error(InvalidDataException("La fecha inicial no puede ser mayor que la final"))
        }
        return statsRepository.getSalesByDate(from, to)
    }

    fun topProducts(limit: Int = PaginationDefaults.DEFAULT_SIZE): Flux<TopProductStat> {
        val safeLimit = if (limit <= 0) PaginationDefaults.DEFAULT_SIZE else limit
        return statsRepository.getTopProducts(safeLimit)
    }
}

