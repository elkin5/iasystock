package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.helpers

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions.route
import org.springframework.web.reactive.function.server.ServerResponse
import org.springframework.web.reactive.function.server.RequestPredicates.GET

@Configuration
class HealthRouter {

    @Bean
    fun healthRoutes(handler: HealthHandler): RouterFunction<ServerResponse> =
        route(GET("/health"), handler::getStatus)
}