package com.co.kinsoft.api.iasy_stock_api.domain.usecase.category

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.category.Category

object CategoryValidator {

    fun validate(category: Category) {
        validateName(category.name)
        category.description?.let { validateDescription(it) }
    }

    private fun validateName(name: String) {
        if (name.isBlank()) {
            throw NullFieldException("El nombre de la categoría no puede estar en blanco.")
        }
        if (name.length > 100) {
            throw InvalidDataException("El nombre de la categoría no puede exceder los 100 caracteres.")
        }
    }

    private fun validateDescription(description: String) {
        if (description.length > 255) {
            throw InvalidDataException("La descripción no puede exceder los 255 caracteres.")
        }
    }
}