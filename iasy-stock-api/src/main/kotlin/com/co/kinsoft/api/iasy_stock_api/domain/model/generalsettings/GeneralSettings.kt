package com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings

data class GeneralSettings(
    val id: Long = 0,
    val key: String,
    val value: String,
    val description: String? = null
) {
    fun isValid(): Boolean = key.isNotBlank() && value.isNotBlank()
    
    fun hasDescription(): Boolean = description != null && description.isNotBlank()
    
    fun getDisplayKey(): String = key.takeIf { it.isNotBlank() } ?: "Sin clave"
    fun getDisplayValue(): String = value.takeIf { it.isNotBlank() } ?: "Sin valor"
    fun getDisplayDescription(): String = description?.takeIf { it.isNotBlank() } ?: "Sin descripción"
    fun getDisplaySummary(): String = "$key: $value"

    override fun toString(): String {
        return """
            {
                "id": $id,
                "key": "$key",
                "value": "$value",
                "description": "${description ?: "Sin descripción"}",
                "isValid": ${isValid()}
            }
        """.trimIndent()
    }
}