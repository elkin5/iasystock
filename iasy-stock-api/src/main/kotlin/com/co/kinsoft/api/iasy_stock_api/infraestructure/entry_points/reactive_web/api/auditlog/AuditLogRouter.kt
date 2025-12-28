package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.auditlog

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.*
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

@Configuration
class AuditLogRouter(private val handler: AuditLogHandler) {

    @Bean
    fun auditLogRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(path("/api/audit-logs"),
        RouterFunctions.route()
            .GET("", handler::findAll)
            .GET("/{id}", handler::findById)
            .POST("", handler::save)
            .DELETE("/{id}", handler::delete)
            .GET("/search/by-user", handler::findByUserId)
            .GET("/search/by-action", handler::findByAction)
            .GET("/search/by-date", handler::findByCreatedAtBetween)
            .DELETE("/delete/by-user", handler::deleteByUserId)
            .build()
    )
}