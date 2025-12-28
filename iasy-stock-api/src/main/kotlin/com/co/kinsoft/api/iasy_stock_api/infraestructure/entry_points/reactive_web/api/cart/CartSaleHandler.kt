package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.cart

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.model.cart.CartSale
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.cart.CartSaleUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class CartSaleHandler(
    private val cartSaleUseCase: CartSaleUseCase,
) {

    private val logger: Logger = LoggerFactory.getLogger(CartSaleHandler::class.java)

    /**
     * Procesar carrito de compras (crear venta completa)
     */
    fun processCart(request: ServerRequest): Mono<ServerResponse> {
        logger.info("Iniciando procesamiento de carrito de compras")
        return request.bodyToMono(CartSale::class.java)
            .flatMap { cartSaleUseCase.processCart(it) }
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

        logger.info("Consultando carritos de compra - page={}, size={}", page, size)

        return ServerResponse.ok().body(cartSaleUseCase.findAll(page, size), CartSale::class.java)
    }

    companion object {
        private const val DEFAULT_PAGE_SIZE = 20
    }
}
