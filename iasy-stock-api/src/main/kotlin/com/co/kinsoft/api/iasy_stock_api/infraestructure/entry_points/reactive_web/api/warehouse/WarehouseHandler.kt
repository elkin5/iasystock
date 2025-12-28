package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.warehouse

import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.Warehouse
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.warehouse.WarehouseUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class WarehouseHandler(private val warehouseUseCase: WarehouseUseCase) {
    val logger: Logger = LoggerFactory.getLogger(WarehouseHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(warehouseUseCase.findAll(page, size), Warehouse::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return warehouseUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Warehouse::class.java)
            .flatMap { warehouseUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Warehouse::class.java)
            .flatMap { warehouseUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return warehouseUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByName(request: ServerRequest): Mono<ServerResponse> {
        val name = request.queryParam("name").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(warehouseUseCase.findByName(name, page, size), Warehouse::class.java)
    }

    fun findByNameContaining(request: ServerRequest): Mono<ServerResponse> {
        val name = request.queryParam("name").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(warehouseUseCase.findByNameContaining(name, page, size), Warehouse::class.java)
    }

    fun findByLocation(request: ServerRequest): Mono<ServerResponse> {
        val location = request.queryParam("location").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(warehouseUseCase.findByLocation(location, page, size), Warehouse::class.java)
    }
}