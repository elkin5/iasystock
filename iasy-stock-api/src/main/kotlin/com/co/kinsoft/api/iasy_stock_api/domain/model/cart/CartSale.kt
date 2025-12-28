package com.co.kinsoft.api.iasy_stock_api.domain.model.cart

import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import java.math.BigDecimal

/**
 * Modelo para representar un carrito de compras completo
 * Incluye la venta y todos sus items
 */
data class CartSale(
    val sale: Sale,
    val saleItems: List<SaleItem>
) {
    fun isValid(): Boolean = sale.isValid() && saleItems.isNotEmpty()
            && saleItems.all { it.isValid() } && isTotalAmountCorrect()

    fun hasItems(): Boolean = saleItems.isNotEmpty()

    fun getTotalItems(): Int = saleItems.size

    fun getTotalQuantity(): Int = saleItems.sumOf { it.quantity }

    fun getTotalAmount(): BigDecimal = saleItems.sumOf { it.totalPrice }

    fun isTotalAmountCorrect(): Boolean = sale.totalAmount == getTotalAmount()

    fun hasValidItems(): Boolean = saleItems.all { it.isValid() }

    fun getItemsByProductId(productId: Long): List<SaleItem> =
        saleItems.filter { it.productId == productId }

    fun getUniqueProductCount(): Int = saleItems.map { it.productId }.distinct().size

    fun getDisplaySummary(): String =
        "Venta: ${sale.id}, Items: ${getTotalItems()}, Total: ${getTotalAmount()}"

    override fun toString(): String {
        return """
            CartSale {
                sale: $sale,
                saleItems: $saleItems,
                totalItems: ${getTotalItems()},
                totalQuantity: ${getTotalQuantity()},
                totalAmount: ${getTotalAmount()}
            }
        """.trimIndent()
    }
}
