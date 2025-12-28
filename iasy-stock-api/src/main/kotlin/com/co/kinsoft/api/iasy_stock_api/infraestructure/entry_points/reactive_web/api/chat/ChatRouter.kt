package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.chat

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class ChatRouter(private val handler: ChatHandler) {

    @Bean
    fun chatRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(
        path("/api/chat"),
        RouterFunctions.route()
            .POST("/process", handler::processMessage)
            .build()
    )
} 