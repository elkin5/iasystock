package com.co.kinsoft.api.iasy_stock_api.domain.model.category

data class Category(
    val id: Long = 0,
    val name: String,
    val description: String? = null
) {
    fun hasDescription(): Boolean = !description.isNullOrBlank()
    
    fun isValid(): Boolean = name.isNotBlank()
    
    fun getDisplayDescription(): String = description?.takeIf { it.isNotBlank() } ?: "Sin descripción"

    override fun toString(): String {
        return """
            {
                "id": $id,
                "name": "$name",
                "description": "${getDisplayDescription()}"
            }
        """.trimIndent()
    }
}