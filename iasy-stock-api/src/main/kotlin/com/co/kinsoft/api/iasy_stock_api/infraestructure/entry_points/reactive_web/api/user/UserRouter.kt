package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.user

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class UserRouter(private val handler: UserHandler) {

    @Bean
    fun userRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/users"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-username", handler::findByUsername)
            .GET("/search/by-email", handler::findByEmail)
            .GET("/search/by-role", handler::findByRole)
            .build()
    )
}