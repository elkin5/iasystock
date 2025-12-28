package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.category

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class CategoryRouter(private val handler: CategoryHandler) {

    @Bean
    fun categoryRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/categories"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-name", handler::findByName)
            .GET("/search/by-name-containing", handler::findByNameContaining)
            .build()
    )
}