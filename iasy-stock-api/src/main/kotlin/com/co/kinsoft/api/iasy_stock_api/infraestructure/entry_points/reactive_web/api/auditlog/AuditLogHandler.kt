package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.auditlog

import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.AuditLog
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.auditlog.AuditLogUseCase
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.time.LocalDateTime

@Component
class AuditLogHandler(private val auditLogUseCase: AuditLogUseCase) {

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(auditLogUseCase.findAll(page, size), AuditLog::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return auditLogUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun save(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(AuditLog::class.java)
            .flatMap { auditLogUseCase.save(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return auditLogUseCase.deleteById(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByUserId(request: ServerRequest): Mono<ServerResponse> {
        val userId = request.queryParam("userId").map { it.toLong() }.orElse(0)
        return ServerResponse.ok().body(auditLogUseCase.findByUserId(userId), AuditLog::class.java)
    }

    fun findByAction(request: ServerRequest): Mono<ServerResponse> {
        val action = request.queryParam("action").orElse("")
        return ServerResponse.ok().body(auditLogUseCase.findByAction(action), AuditLog::class.java)
    }

    fun findByCreatedAtBetween(request: ServerRequest): Mono<ServerResponse> {
        val startParam = request.queryParam("start").orElse(null)
        val endParam = request.queryParam("end").orElse(null)

        if (startParam.isNullOrBlank() || endParam.isNullOrBlank()) {
            return ServerResponse.badRequest().bodyValue("Los parámetros 'start' y 'end' son requeridos.")
        }

        val start = LocalDateTime.parse(startParam)
        val end = LocalDateTime.parse(endParam)

        return ServerResponse.ok().body(auditLogUseCase.findByCreatedAtBetween(start, end), AuditLog::class.java)
    }

    fun deleteByUserId(request: ServerRequest): Mono<ServerResponse> {
        val userId = request.queryParam("userId").map { it.toLong() }.orElse(0)
        return auditLogUseCase.deleteByUserId(userId)
            .then(ServerResponse.noContent().build())
    }
}