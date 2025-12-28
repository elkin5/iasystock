package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.stock

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class StockRouter(private val handler: StockHandler) {

    @Bean
    fun stockRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/stocks"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-product", handler::findByProductId)
            .GET("/search/by-warehouse", handler::findByWarehouseId)
            .GET("/search/by-user", handler::findByUserId)
            .GET("/search/by-person", handler::findByPersonId)
            .GET("/search/by-entry-date", handler::findByEntryDate)
            .GET("/search/by-quantity", handler::findByQuantityGreaterThan)
            .build()
    )
}