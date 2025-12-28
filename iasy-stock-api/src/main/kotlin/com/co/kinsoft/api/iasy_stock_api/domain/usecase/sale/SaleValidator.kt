package com.co.kinsoft.api.iasy_stock_api.domain.usecase.sale

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import java.math.BigDecimal

object SaleValidator {

    fun validate(sale: Sale) {
        validateUserId(sale.userId)
        validatePersonId(sale.personId)
        validateTotalAmount(sale.totalAmount)
        sale.payMethod?.let { validatePayMethod(it) }
        sale.state?.let { validateState(it) }
    }

    private fun validateUserId(userId: Long) {
        if (userId <= 0) {
            throw InvalidDataException("El ID del usuario debe ser un valor positivo.")
        }
    }

    private fun validatePersonId(personId: Long?) {
        if (personId == null || personId <= 0) {
            throw InvalidDataException("La venta debe tener un cliente asociado.")
        }
    }

    private fun validateTotalAmount(amount: BigDecimal) {
        if (amount < BigDecimal.ZERO) {
            throw InvalidDataException("El monto total de la venta no puede ser negativo.")
        }
    }

    private fun validatePayMethod(payMethod: String) {
        if (payMethod.length > 50) {
            throw InvalidDataException("El método de pago no puede exceder los 50 caracteres.")
        }
    }

    private fun validateState(state: String) {
        if (state.length > 50) {
            throw InvalidDataException("El estado de la venta no puede exceder los 50 caracteres.")
        }
    }
}