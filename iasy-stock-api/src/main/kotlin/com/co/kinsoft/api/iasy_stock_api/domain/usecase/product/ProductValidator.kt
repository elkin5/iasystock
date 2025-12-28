package com.co.kinsoft.api.iasy_stock_api.domain.usecase.product

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import java.math.BigDecimal

object ProductValidator {

    fun validate(product: Product) {
        validateName(product.name)
        validateCategoryId(product.categoryId)
        validateStockQuantity(product.stockQuantity)
        validateStockMinimum(product.stockMinimum)
    }

    private fun validateName(name: String) {
        if (name.isBlank()) {
            throw NullFieldException("El nombre del producto no puede estar en blanco.")
        }
        if (name.length > 100) {
            throw InvalidDataException("El nombre del producto no puede exceder los 100 caracteres.")
        }
    }

    private fun validateCategoryId(categoryId: Long) {
        if (categoryId <= 0) {
            throw InvalidDataException("El ID de categoría debe ser un valor positivo.")
        }
    }

    private fun validateStockQuantity(stockQuantity: Int?) {
        if (stockQuantity != null && stockQuantity < 0) {
            throw InvalidDataException("La cantidad en inventario no puede ser negativa.")
        }
    }

    private fun validateStockMinimum(stockMinimum: Int?) {
        if (stockMinimum != null && stockMinimum < 0) {
            throw InvalidDataException("La cantidad mínima en inventario no puede ser negativa.")
        }
    }
}