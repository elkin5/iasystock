package com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem

import java.math.BigDecimal

data class SaleItem(
    val id: Long = 0,
    val saleId: Long,
    val productId: Long,
    val quantity: Int,
    val unitPrice: BigDecimal,
    val totalPrice: BigDecimal
) {
    fun isValid(): Boolean = productId > 0 && hasValidQuantity() && hasValidPrices()
    
    fun calculateTotal(): BigDecimal = unitPrice * BigDecimal(quantity)
    
    fun isTotalPriceCorrect(): Boolean = totalPrice == calculateTotal()
    
    fun hasValidQuantity(): Boolean = quantity > 0
    
    fun hasValidPrices(): Boolean = unitPrice > BigDecimal.ZERO && totalPrice > BigDecimal.ZERO

    override fun toString(): String {
        return """
            {
                "id": $id,
                "saleId": $saleId,
                "productId": $productId,
                "quantity": $quantity,
                "unitPrice": $unitPrice,
                "totalPrice": $totalPrice,
                "calculatedTotal": ${calculateTotal()},
                "isValid": ${isTotalPriceCorrect()}
            }
        """.trimIndent()
    }
}