package com.co.kinsoft.api.iasy_stock_api.domain.usecase.warehouse

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.Warehouse

object WarehouseValidator {

    fun validate(warehouse: Warehouse) {
        validateName(warehouse.name)
        warehouse.location?.let { validateLocation(it) }
    }

    private fun validateName(name: String) {
        if (name.isBlank()) {
            throw NullFieldException("El nombre del almacén no puede estar en blanco.")
        }
        if (name.length > 100) {
            throw InvalidDataException("El nombre del almacén no puede exceder los 100 caracteres.")
        }
    }

    private fun validateLocation(location: String) {
        if (location.length > 255) {
            throw InvalidDataException("La ubicación del almacén no puede exceder los 255 caracteres.")
        }
    }
}