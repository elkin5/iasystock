package com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock
import java.math.BigDecimal

object StockValidator {

    fun validate(stock: Stock) {
        validateQuantity(stock.quantity)
        validateEntryPrice(stock.entryPrice)
        validateSalePrice(stock.salePrice)
        validateProductId(stock.productId)
        validateUserId(stock.userId)
    }

    private fun validateQuantity(quantity: Int) {
        if (quantity < 0) {
            throw InvalidDataException("La cantidad de productos no puede ser negativa.")
        }
    }

    private fun validateEntryPrice(entryPrice: BigDecimal) {
        if (entryPrice < BigDecimal.ZERO) {
            throw InvalidDataException("El precio de entrada no puede ser negativo.")
        }
    }

    private fun validateSalePrice(salePrice: BigDecimal) {
        if (salePrice < BigDecimal.ZERO) {
            throw InvalidDataException("El precio de venta no puede ser negativo.")
        }
    }

    private fun validateProductId(productId: Long) {
        if (productId <= 0) {
            throw InvalidDataException("El ID del producto debe ser un valor positivo.")
        }
    }

    private fun validateUserId(userId: Long) {
        if (userId <= 0) {
            throw InvalidDataException("El ID del usuario debe ser un valor positivo.")
        }
    }
}