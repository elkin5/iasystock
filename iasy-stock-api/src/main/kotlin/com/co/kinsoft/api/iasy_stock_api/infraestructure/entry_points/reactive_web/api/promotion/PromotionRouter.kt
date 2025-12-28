package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.promotion

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class PromotionRouter(private val handler: PromotionHandler) {

    @Bean
    fun promotionRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/promotions"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-description", handler::findByDescription)
            .GET("/search/by-discount-gt", handler::findByDiscountRateGreaterThan)
            .GET("/search/by-date-range", handler::findByDateRange)
            .GET("/search/by-product", handler::findByProductId)
            .GET("/search/by-category", handler::findByCategoryId)
            .build()
    )
}