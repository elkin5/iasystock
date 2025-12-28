package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.stats

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.GET
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class StatsRouter(
    private val handler: StatsHandler
) {

    @Bean
    fun statsRoutes(): RouterFunction<ServerResponse> = RouterFunctions.route()
        .GET("/api/stats/sales-by-date", handler::salesByDate)
        .GET("/api/stats/top-products", handler::topProducts)
        .build()
}

