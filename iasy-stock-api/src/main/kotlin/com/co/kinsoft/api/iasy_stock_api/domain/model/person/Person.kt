package com.co.kinsoft.api.iasy_stock_api.domain.model.person

import java.time.LocalDateTime

data class Person(
    val id: Long = 0,
    val name: String,
    val identification: Long? = null,
    val identificationType: String? = null,
    val cellPhone: Long? = null,
    val email: String? = null,
    val address: String? = null,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val type: String
) {
    fun isCustomer(): Boolean = type.equals("Customer", ignoreCase = true)
    fun isSupplier(): Boolean = type.equals("Supplier", ignoreCase = true)
    
    fun isValid(): Boolean = name.isNotBlank() && type.isNotBlank()
    
    fun hasIdentification(): Boolean = identification != null && identification > 0
    
    fun hasContactInfo(): Boolean = !email.isNullOrBlank() || !address.isNullOrBlank() || cellPhone != null
    
    fun getDisplayIdentification(): String = identification?.toString() ?: "Sin identificación"
    
    fun getDisplayContact(): String {
        val parts = mutableListOf<String>()
        if (!email.isNullOrBlank()) parts.add("Email: $email")
        if (cellPhone != null) parts.add("Tel: $cellPhone")
        if (!address.isNullOrBlank()) parts.add("Dir: $address")
        return parts.joinToString(" | ").takeIf { it.isNotEmpty() } ?: "Sin información de contacto"
    }

    override fun toString(): String {
        return """
            {
                "id": $id,
                "name": "$name",
                "identification": "${getDisplayIdentification()}",
                "identificationType": "${identificationType ?: "Sin tipo de identificación"}",
                "cellPhone": ${cellPhone ?: "Sin teléfono"},
                "email": "${email ?: "Sin correo"}",
                "address": "${address ?: "Sin dirección"}",
                "createdAt": "$createdAt",
                "type": "$type"
            }
        """.trimIndent()
    }
}