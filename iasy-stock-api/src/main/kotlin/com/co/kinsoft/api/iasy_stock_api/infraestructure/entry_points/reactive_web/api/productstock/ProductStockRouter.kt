package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.productstock

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class ProductStockRouter(private val handler: ProductStockHandler) {

    @Bean
    fun productStockRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(
        path("/api/v1/product_stock"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .POST("/process", handler::create)
            .build()
    )
}
