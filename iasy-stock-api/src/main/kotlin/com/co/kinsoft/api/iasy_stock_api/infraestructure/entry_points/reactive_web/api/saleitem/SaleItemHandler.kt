package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.saleitem

import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.saleitem.SaleItemUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class SaleItemHandler(private val saleItemUseCase: SaleItemUseCase) {
    val logger: Logger = LoggerFactory.getLogger(SaleItemHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleItemUseCase.findAll(page, size), SaleItem::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return saleItemUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(SaleItem::class.java)
            .flatMap { saleItemUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(SaleItem::class.java)
            .flatMap { saleItemUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return saleItemUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findBySaleId(request: ServerRequest): Mono<ServerResponse> {
        val saleId = request.queryParam("saleId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("saleId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleItemUseCase.findBySaleId(saleId, page, size), SaleItem::class.java)
    }

    fun findByProductId(request: ServerRequest): Mono<ServerResponse> {
        val productId = request.queryParam("productId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("productId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleItemUseCase.findByProductId(productId, page, size), SaleItem::class.java)
    }

    fun calculateTotalBySaleId(request: ServerRequest): Mono<ServerResponse> {
        val saleId = request.pathVariable("saleId").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("saleId inválido")

        return saleItemUseCase.calculateTotalBySaleId(saleId)
            .flatMap { total -> 
                ServerResponse.ok().bodyValue(mapOf("total" to total))
            }
    }
}