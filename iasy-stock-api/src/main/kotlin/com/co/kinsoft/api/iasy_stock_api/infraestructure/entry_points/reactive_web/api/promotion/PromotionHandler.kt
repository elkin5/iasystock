package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.promotion

import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.Promotion
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.promotion.PromotionUseCase
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
class PromotionHandler(private val promotionUseCase: PromotionUseCase) {
    val logger: Logger = LoggerFactory.getLogger(PromotionHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(promotionUseCase.findAll(page, size), Promotion::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return promotionUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Promotion::class.java)
            .flatMap { promotionUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Promotion::class.java)
            .flatMap { promotionUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return promotionUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByDescription(request: ServerRequest): Mono<ServerResponse> {
        val description = request.queryParam("description").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok()
            .body(promotionUseCase.findByDescription(description, page, size), Promotion::class.java)
    }

    fun findByDiscountRateGreaterThan(request: ServerRequest): Mono<ServerResponse> {
        val rate = request.queryParam("rate").map { BigDecimal(it) }.orElse(BigDecimal.ZERO)
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok()
            .body(promotionUseCase.findByDiscountRateGreaterThan(rate, page, size), Promotion::class.java)
    }

    fun findByDateRange(request: ServerRequest): Mono<ServerResponse> {
        val startDate =
            request.queryParam("startDate").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)
        val endDate = request.queryParam("endDate").map { runCatching { LocalDate.parse(it) }.getOrNull() }.orElse(null)
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)

        return if (startDate != null && endDate != null) {
            ServerResponse.ok().body(
                promotionUseCase.findByStartDateBeforeAndEndDateAfter(startDate, endDate, page, size),
                Promotion::class.java
            )
        } else {
            ServerResponse.badRequest()
                .bodyValue("startDate y endDate son requeridos y deben estar en formato yyyy-MM-dd")
        }
    }

    fun findByProductId(request: ServerRequest): Mono<ServerResponse> {
        val productId = request.queryParam("productId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("productId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)

        return ServerResponse.ok().body(promotionUseCase.findByProductId(productId, page, size), Promotion::class.java)
    }

    fun findByCategoryId(request: ServerRequest): Mono<ServerResponse> {
        val categoryId = request.queryParam("categoryId").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("categoryId es requerido")

        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)

        return ServerResponse.ok()
            .body(promotionUseCase.findByCategoryId(categoryId, page, size), Promotion::class.java)
    }
}