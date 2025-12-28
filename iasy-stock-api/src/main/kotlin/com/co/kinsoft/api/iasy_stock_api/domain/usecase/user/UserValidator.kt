package com.co.kinsoft.api.iasy_stock_api.domain.usecase.user

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.EmailFormatException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserCreateDTO
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserRole


object UserValidator {
    fun validate(user: User) {
        validateUsername(user.username)
        // Solo validar password si no es un usuario OIDC
        if (user.isLocalUser()) {
            validatePassword(user.password!!)
        }
        validateRole(user.role)
        user.email?.let { validateEmail(it) }
    }

    fun validateCreateDTO(dto: UserCreateDTO) {
        validateUsername(dto.username)
        validateRole(dto.role)
        dto.email?.let { validateEmail(it) }
        dto.firstName?.let { validateName(it, "nombre") }
        dto.lastName?.let { validateName(it, "apellido") }
    }

    private fun validateUsername(username: String) {
        if (username.isBlank()) {
            throw NullFieldException("El nombre de usuario no puede estar en blanco.")
        }
        if (username.length > 50) {
            throw InvalidDataException("El nombre de usuario no puede exceder los 50 caracteres.")
        }
    }

    private fun validatePassword(password: String) {
        if (password.isBlank()) {
            throw NullFieldException("La contraseña no puede estar en blanco.")
        }
    }

    private fun validateRole(role: String) {
        if (role.isBlank()) {
            throw NullFieldException("El rol del usuario no puede estar en blanco.")
        }
        if (!UserRole.isValid(role)) {
            throw InvalidDataException("El rol '$role' no es válido. Roles permitidos: ${UserRole.getAllRoles().joinToString(", ")}")
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

    private fun validateName(name: String, fieldName: String) {
        if (name.isBlank()) {
            throw NullFieldException("El $fieldName no puede estar en blanco.")
        }
        if (name.length > 50) {
            throw InvalidDataException("El $fieldName no puede exceder los 50 caracteres.")
        }
    }

    private val EMAIL_REGEX = Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$")
}