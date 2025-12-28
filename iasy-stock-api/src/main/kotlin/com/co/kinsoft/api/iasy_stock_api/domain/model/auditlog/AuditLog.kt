package com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog

import java.time.LocalDateTime

data class AuditLog(
    val id: Long = 0,
    val userId: Long,
    val action: String,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val description: String? = null
) {
    fun isValid(): Boolean = userId > 0 && action.isNotBlank()
    
    fun hasDescription(): Boolean = description != null && description.isNotBlank()
    
    fun getDisplayAction(): String = action.takeIf { it.isNotBlank() } ?: "Sin acción"
    fun getDisplayDescription(): String = description?.takeIf { it.isNotBlank() } ?: "Sin descripción"
    fun getDisplayUserId(): String = "Usuario ID: $userId"
    fun getDisplayCreatedAt(): String = createdAt.toString()
    fun getDisplaySummary(): String = "$action - ${getDisplayDescription()}"

    override fun toString(): String {
        return """
            {
                "id": $id,
                "userId": $userId,
                "action": "$action",
                "createdAt": "$createdAt",
                "description": "${description ?: "Sin descripción"}",
                "isValid": ${isValid()}
            }
        """.trimIndent()
    }
}