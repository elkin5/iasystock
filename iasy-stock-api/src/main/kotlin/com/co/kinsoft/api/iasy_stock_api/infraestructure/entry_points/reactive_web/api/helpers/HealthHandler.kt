package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.helpers

import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.time.Instant

@Component
class HealthHandler {

    fun getStatus(request: ServerRequest): Mono<ServerResponse> {
        val response = mapOf(
            "status" to "UP",
            "timestamp" to Instant.now().toString()
        )
        return ServerResponse.ok()
            .contentType(MediaType.APPLICATION_JSON)
            .bodyValue(response)
    }
}