package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.stats

import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stats.StatsUseCase
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.time.LocalDate

@Component
class StatsHandler(
    private val statsUseCase: StatsUseCase
) {

    fun salesByDate(request: ServerRequest): Mono<ServerResponse> {
        val from = request.queryParam("from").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)
        val to = request.queryParam("to").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)

        return ServerResponse.ok().body(statsUseCase.salesByDate(from, to), Any::class.java)
    }

    fun topProducts(request: ServerRequest): Mono<ServerResponse> {
        val limit = request.queryParam("limit").map { runCatching { it.toInt() }.getOrNull() }.orElse(5) ?: 5
        return ServerResponse.ok().body(statsUseCase.topProducts(limit), Any::class.java)
    }
}

