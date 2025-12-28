package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.generalsettings

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class GeneralSettingsRouter(private val handler: GeneralSettingsHandler) {

    @Bean
    fun generalSettingsRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/general-settings"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::create)
            .PUT("/{id}", handler::update)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-key", handler::findByKey)
            .GET("/search/by-key-containing", handler::findByKeyContaining)
            .DELETE("/delete/by-key", handler::deleteByKey)
            .build()
    )
}