package com.co.kinsoft.api.iasy_stock_api.domain.usecase.promotion

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.Promotion
import java.math.BigDecimal

object PromotionValidator {

    fun validate(promotion: Promotion) {
        validateDescription(promotion.description)
        validateDiscountRate(promotion.discountRate)
        validateDates(promotion.startDate, promotion.endDate)
    }

    private fun validateDescription(description: String) {
        if (description.isBlank()) {
            throw NullFieldException("La descripción de la promoción no puede estar en blanco.")
        }
        if (description.length > 255) {
            throw InvalidDataException("La descripción de la promoción no puede exceder los 255 caracteres.")
        }
    }

    private fun validateDiscountRate(discountRate: BigDecimal) {
        if (discountRate <= BigDecimal.ZERO) {
            throw InvalidDataException("La tasa de descuento debe ser mayor a cero.")
        }
        if (discountRate > BigDecimal(100)) {
            throw InvalidDataException("La tasa de descuento no puede ser mayor al 100%.")
        }
    }

    private fun validateDates(startDate: java.time.LocalDate, endDate: java.time.LocalDate) {
        if (endDate.isBefore(startDate)) {
            throw InvalidDataException("La fecha de finalización debe ser igual o posterior a la fecha de inicio.")
        }
    }
}