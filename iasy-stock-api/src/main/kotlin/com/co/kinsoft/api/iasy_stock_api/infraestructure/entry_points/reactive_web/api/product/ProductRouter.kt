package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.product

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.path
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class ProductRouter(private val handler: ProductHandler) {

    @Bean
    fun productRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(
        path("/api/products"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .POST("/with-recognition", handler::createWithRecognition)
            .PUT("/{id}", handler::update)
            .POST("/{id}/refresh-image-url", handler::refreshImageUrl)
            .DELETE("/{id}", handler::delete)
            
            // Rutas de búsqueda
            .GET("/search/by-name", handler::findByName)
            .GET("/search/by-category", handler::findByCategoryId)
            .GET("/search/by-stock-gt", handler::findByStockQuantityGreaterThan)
            .GET("/search/by-expiration-date", handler::findByExpirationDateBefore)
            .GET("/search/by-barcode", handler::findByBarcodeData)
            .build()
    )
}