package com.co.kinsoft.api.iasy_stock_api.domain.usecase.generalsettings

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.GeneralSettings

object GeneralSettingsValidator {

    fun validate(settings: GeneralSettings) {
        validateKey(settings.key)
        validateValue(settings.value)
        settings.description?.let { validateDescription(it) }
    }

    private fun validateKey(key: String) {
        if (key.isBlank()) {
            throw NullFieldException("La clave de configuración no puede estar en blanco.")
        }
        if (key.length > 50) {
            throw InvalidDataException("La clave de configuración no puede exceder los 50 caracteres.")
        }
    }

    private fun validateValue(value: String) {
        if (value.isBlank()) {
            throw NullFieldException("El valor de configuración no puede estar en blanco.")
        }
        if (value.length > 255) {
            throw InvalidDataException("El valor de configuración no puede exceder los 255 caracteres.")
        }
    }

    private fun validateDescription(description: String) {
        if (description.length > 500) {
            throw InvalidDataException("La descripción no puede exceder los 500 caracteres.")
        }
    }
}