package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.saleitem

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class SaleItemRouter(private val handler: SaleItemHandler) {

    @Bean
    fun saleItemRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/sale-items"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-sale", handler::findBySaleId)
            .GET("/search/by-product", handler::findByProductId)
            .GET("/calculate-total/{saleId}", handler::calculateTotalBySaleId)
            .build()
    )
}