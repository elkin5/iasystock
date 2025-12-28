package com.co.kinsoft.api.iasy_stock_api.domain.usecase.saleitem

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import java.math.BigDecimal

object SaleItemValidator {

    fun validate(saleItem: SaleItem) {
        validateQuantity(saleItem.quantity)
        validateUnitPrice(saleItem.unitPrice)
        validateTotalPrice(saleItem.totalPrice)
        validateCalculation(saleItem)
    }

    private fun validateQuantity(quantity: Int) {
        if (quantity <= 0) {
            throw InvalidDataException("La cantidad vendida debe ser mayor a cero.")
        }
    }

    private fun validateUnitPrice(unitPrice: BigDecimal) {
        if (unitPrice < BigDecimal.ZERO) {
            throw InvalidDataException("El precio unitario no puede ser negativo.")
        }
    }

    private fun validateTotalPrice(totalPrice: BigDecimal) {
        if (totalPrice < BigDecimal.ZERO) {
            throw InvalidDataException("El precio total no puede ser negativo.")
        }
    }

    private fun validateCalculation(saleItem: SaleItem) {
        val expectedTotal = saleItem.unitPrice * BigDecimal(saleItem.quantity)
        if (saleItem.totalPrice != expectedTotal) {
            throw InvalidDataException("El precio total debe ser igual al precio unitario multiplicado por la cantidad.")
        }
    }
}