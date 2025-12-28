package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.sale

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class SaleRouter(private val handler: SaleHandler) {

    @Bean
    fun saleRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/sales"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-user", handler::findByUserId)
            .GET("/search/by-person", handler::findByPersonId)
            .GET("/search/by-date", handler::findBySaleDate)
            .GET("/search/by-amount-gt", handler::findByTotalAmountGreaterThan)
            .GET("/search/by-state", handler::findByState)
            .build()
    )
}