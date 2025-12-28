package com.co.kinsoft.api.iasy_stock_api.domain.usecase.cart

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.model.cart.CartSale
import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.sale.SaleUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.saleitem.SaleItemUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock.StockUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

/**
 * Caso de uso para gestionar carritos de compras
 * Maneja la creación de ventas completas con sus items
 */
class CartSaleUseCase(
    private val saleUseCase: SaleUseCase,
    private val saleItemUseCase: SaleItemUseCase,
    private val stockUseCase: StockUseCase
) {

    private val logger: Logger = LoggerFactory.getLogger(CartSaleUseCase::class.java)

    /**
     * Procesa un carrito de compras completo
     * Crea la venta y todos sus items
     */
    fun processCart(cartSale: CartSale): Mono<CartSale> {
        logger.info("Iniciando procesamiento de carrito de compras...")
        return validateCart(cartSale)
            .flatMap { validatedCart ->
                saleUseCase.create(validatedCart.sale)
                    .flatMap { createdSale ->
                        // Crear todos los items de la venta
                        createSaleItems(createdSale.id, validatedCart.saleItems)
                            .collectList()
                            .map { createdItems ->
                                CartSale(
                                    sale = createdSale,
                                    saleItems = createdItems
                                )
                            }
                    }
            }
    }

    /**
     * Obtiene los carritos de compra paginados combinando la venta con sus items
     */
    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<CartSale> {
        logger.info("Consultando carritos de compras: page=$page, size=$size")

        return saleUseCase.findAll(page, size)
            .flatMap { sale ->
                if (sale.id <= 0) {
                    Mono.error(InvalidDataException("La venta consultada no tiene un ID válido."))
                } else {
                    saleItemUseCase.findBySaleId(sale.id)
                        .collectList()
                        .map { saleItems -> CartSale(sale = sale, saleItems = saleItems) }
                }
            }
    }

    /**
     * Valida un carrito de compras antes de procesarlo
     */
    private fun validateCart(cartSale: CartSale): Mono<CartSale> {
        logger.info("Validando carrito de compras...")
        return Mono.fromCallable {
            if (!cartSale.isValid()) {
                throw InvalidDataException("El carrito de compras no es válido")
            }

            if (!cartSale.hasItems()) {
                throw InvalidDataException("El carrito debe contener al menos un item")
            }

            if (!cartSale.hasValidItems()) {
                throw InvalidDataException("El carrito contiene items inválidos")
            }

            // Validar que el total calculado coincida con el total de la venta
            val calculatedTotal = cartSale.getTotalAmount()
            if (cartSale.sale.totalAmount != calculatedTotal) {
                throw InvalidDataException("El total calculado no coincide con el total de la venta")
            }

            cartSale
        }
    }

    /**
     * Crea todos los items de una venta
     */
    private fun createSaleItems(saleId: Long, saleItems: List<SaleItem>): Flux<SaleItem> {
        logger.info("Creando items para la venta $saleId...")

        return Flux.fromIterable(saleItems)
            .flatMap { saleItem ->
                val itemToCreate = saleItem.copy(saleId = saleId)

                // Validar stock disponible antes de crear el item
                validateStockAvailability(itemToCreate)
                    .then(saleItemUseCase.create(itemToCreate))
            }
    }

    /**
     * Valida que haya stock suficiente para un item
     */
    private fun validateStockAvailability(saleItem: SaleItem): Mono<Void> {
        logger.info("Validando stock para producto ${saleItem.productId}...")
        return stockUseCase.findByProductId(saleItem.productId)
            .collectList()
            .flatMap { stocks ->
                val totalStock = stocks.sumOf { it.quantity }

                if (totalStock < saleItem.quantity) {
                    Mono.error(InvalidDataException("Stock insuficiente para el producto ${saleItem.productId}. Disponible: $totalStock, Requerido: ${saleItem.quantity}"))
                } else {
                    Mono.empty()
                }
            }
    }
}
