package com.co.kinsoft.api.iasy_stock_api.domain.usecase.auditlog

import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NullFieldException
import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.AuditLog

object AuditLogValidator {

    fun validate(auditLog: AuditLog) {
        validateUserId(auditLog.userId)
        validateAction(auditLog.action)
        auditLog.description?.let { validateDescription(it) }
    }

    private fun validateUserId(userId: Long) {
        if (userId <= 0) {
            throw InvalidDataException("El ID de usuario debe ser un valor positivo.")
        }
    }

    private fun validateAction(action: String) {
        if (action.isBlank()) {
            throw NullFieldException("La acción no puede estar en blanco.")
        }
        if (action.length > 255) {
            throw InvalidDataException("La descripción de la acción no puede exceder los 255 caracteres.")
        }
    }

    private fun validateDescription(description: String) {
        if (description.length > 500) {
            throw InvalidDataException("La descripción no puede exceder los 500 caracteres.")
        }
    }
}