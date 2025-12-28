package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.productstock

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.model.productstock.ProductStock
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.productstock.ProductStockFlowUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class ProductStockHandler(
    private val productStockFlowUseCase: ProductStockFlowUseCase
) {

    private val logger: Logger = LoggerFactory.getLogger(ProductStockHandler::class.java)

    fun create(request: ServerRequest): Mono<ServerResponse> {
        logger.info("Recibiendo solicitud para registrar producto con stock")
        return request.bodyToMono(ProductStock::class.java)
            .flatMap { productStockFlowUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page")
            .orElse(null)
            ?.toIntOrNull()
            ?.takeIf { it >= 0 }
            ?: DEFAULT_PAGE

        val size = request.queryParam("size")
            .orElse(null)
            ?.toIntOrNull()
            ?.takeIf { it > 0 }
            ?: DEFAULT_PAGE_SIZE

        logger.info("Consultando productos con stock - page={}, size={}", page, size)

        return ServerResponse.ok().body(productStockFlowUseCase.findAll(page, size), ProductStock::class.java)
    }

    companion object {
        private const val DEFAULT_PAGE_SIZE = 20
    }
}
