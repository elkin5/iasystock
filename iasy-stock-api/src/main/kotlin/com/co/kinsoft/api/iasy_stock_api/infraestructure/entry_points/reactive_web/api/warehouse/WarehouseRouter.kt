package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.warehouse

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class WarehouseRouter(private val handler: WarehouseHandler) {

    @Bean
    fun warehouseRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/warehouses"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-name", handler::findByName)
            .GET("/search/by-name-containing", handler::findByNameContaining)
            .GET("/search/by-location", handler::findByLocation)
            .build()
    )
}