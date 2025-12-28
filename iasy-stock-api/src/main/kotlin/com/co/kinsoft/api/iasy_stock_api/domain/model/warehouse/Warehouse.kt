package com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse

import java.time.LocalDateTime

data class Warehouse(
    val id: Long = 0,
    val name: String,
    val location: String? = null,
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    fun isValid(): Boolean = name.isNotBlank()
    
    fun hasLocation(): Boolean = !location.isNullOrBlank()
    
    fun getDisplayLocation(): String = location?.takeIf { it.isNotBlank() } ?: "Sin ubicación"

    override fun toString(): String {
        return """
            {
                "id": $id,
                "name": "$name",
                "location": "${getDisplayLocation()}",
                "createdAt": "$createdAt"
            }
        """.trimIndent()
    }
}