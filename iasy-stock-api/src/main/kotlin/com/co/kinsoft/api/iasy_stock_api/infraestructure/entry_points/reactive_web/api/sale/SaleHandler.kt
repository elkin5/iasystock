package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.sale

import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.sale.SaleUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

@Component
class SaleHandler(private val saleUseCase: SaleUseCase) {
    val logger: Logger = LoggerFactory.getLogger(SaleHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleUseCase.findAll(page, size), Sale::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return saleUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Sale::class.java)
            .flatMap { saleUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Sale::class.java)
            .flatMap { saleUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return saleUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByUserId(request: ServerRequest): Mono<ServerResponse> {
        val userId = request.queryParam("userId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("userId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleUseCase.findByUserId(userId, page, size), Sale::class.java)
    }

    fun findByPersonId(request: ServerRequest): Mono<ServerResponse> {
        val personId = request.queryParam("personId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("personId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleUseCase.findByPersonId(personId, page, size), Sale::class.java)
    }

    fun findBySaleDate(request: ServerRequest): Mono<ServerResponse> {
        val saleDate =
            request.queryParam("saleDate").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)
                ?: return ServerResponse.badRequest()
                    .bodyValue("saleDate es requerido y debe estar en formato yyyy-MM-dd")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleUseCase.findBySaleDate(saleDate, page, size), Sale::class.java)
    }

    fun findByTotalAmountGreaterThan(request: ServerRequest): Mono<ServerResponse> {
        val amount = request.queryParam("amount").map { runCatching { BigDecimal(it) }.getOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("amount es requerido y debe ser un número válido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleUseCase.findByTotalAmountGreaterThan(amount, page, size), Sale::class.java)
    }

    fun findByState(request: ServerRequest): Mono<ServerResponse> {
        val state = request.queryParam("state").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(saleUseCase.findByState(state, page, size), Sale::class.java)
    }
}