package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.ServerResponse
import org.springframework.web.reactive.function.server.router

/**
 * Router para el proxy de imágenes
 */
@Configuration
class ImageProxyRouter(private val imageProxyHandler: ImageProxyHandler) {
    
    @Bean
    fun imageProxyRoutes(): RouterFunction<ServerResponse> = router {
        "/api/images".nest {
            GET("/proxy", imageProxyHandler::proxyImage)
        }
    }
}
