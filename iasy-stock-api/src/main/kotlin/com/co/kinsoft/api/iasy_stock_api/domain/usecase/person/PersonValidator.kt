package com.co.kinsoft.api.iasy_stock_api.domain.usecase.person

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.EmailFormatException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.person.Person

object PersonValidator {

    fun validate(person: Person) {
        validateName(person.name)
        validateType(person.type)
        person.identificationType?.let { validateIdentificationType(it) }
        person.email?.let { validateEmail(it) }
    }

    private fun validateName(name: String) {
        if (name.isBlank()) {
            throw NullFieldException("El nombre de la persona no puede estar en blanco.")
        }
        if (name.length > 100) {
            throw InvalidDataException("El nombre de la persona no puede exceder los 100 caracteres.")
        }
    }

    private fun validateIdentificationType(type: String) {
        if (type.length > 20) {
            throw InvalidDataException("El tipo de identificación no puede exceder los 20 caracteres.")
        }
    }

    private fun validateEmail(email: String) {
        if (email.length > 100) {
            throw InvalidDataException("El correo electrónico no puede exceder los 100 caracteres.")
        }
        if (!EMAIL_REGEX.matches(email)) {
            throw EmailFormatException("El formato del email no es válido.")
        }
    }

    private fun validateType(type: String) {
        if (type != "Customer" && type != "Supplier") {
            throw InvalidDataException("El tipo debe ser 'Customer' o 'Supplier'.")
        }
    }

    private val EMAIL_REGEX = Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$")
}