package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.stock

import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock.StockUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.time.LocalDate

@Component
class StockHandler(private val stockUseCase: StockUseCase) {
    val logger: Logger = LoggerFactory.getLogger(StockHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findAll(page, size), Stock::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return stockUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Stock::class.java)
            .flatMap { stockUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Stock::class.java)
            .flatMap { stockUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return stockUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByProductId(request: ServerRequest): Mono<ServerResponse> {
        val productId = request.queryParam("productId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("productId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findByProductId(productId, page, size), Stock::class.java)
    }

    fun findByWarehouseId(request: ServerRequest): Mono<ServerResponse> {
        val warehouseId = request.queryParam("warehouseId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("warehouseId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findByWarehouseId(warehouseId, page, size), Stock::class.java)
    }

    fun findByUserId(request: ServerRequest): Mono<ServerResponse> {
        val userId = request.queryParam("userId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("userId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findByUserId(userId, page, size), Stock::class.java)
    }

    fun findByPersonId(request: ServerRequest): Mono<ServerResponse> {
        val personId = request.queryParam("personId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("personId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findByPersonId(personId, page, size), Stock::class.java)
    }

    fun findByEntryDate(request: ServerRequest): Mono<ServerResponse> {
        val entryDate = request.queryParam("entryDate").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("entryDate es requerido y debe estar en formato yyyy-MM-dd")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findByEntryDate(entryDate, page, size), Stock::class.java)
    }

    fun findByQuantityGreaterThan(request: ServerRequest): Mono<ServerResponse> {
        val quantity = request.queryParam("quantity").map { it.toInt() }.orElse(0)
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(stockUseCase.findByQuantityGreaterThan(quantity, page, size), Stock::class.java)
    }
}