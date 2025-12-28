package com.co.kinsoft.api.iasy_stock_api.domain.model.user

import java.time.LocalDateTime

data class User(
    val id: Long = 0,
    val keycloakId: String? = null, // ID del usuario en Keycloak
    val username: String,
    val password: String? = null, // Nullable para usuarios OIDC
    val email: String? = null,
    val firstName: String? = null,
    val lastName: String? = null,
    val role: String,
    val isActive: Boolean = true,
    val lastLoginAt: LocalDateTime? = null,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    fun isValid(): Boolean = username.isNotBlank() && 
        role.isNotBlank() &&
        (keycloakId != null || password != null) && // Debe tener keycloakId o password
        (email == null || email.isNotBlank()) &&
        (firstName == null || firstName.isNotBlank()) &&
        (lastName == null || lastName.isNotBlank())
    
    fun isAdmin(): Boolean = role.equals("admin", ignoreCase = true)
    
    fun isManager(): Boolean = role.equals("manager", ignoreCase = true) || isAdmin()
    
    fun isUser(): Boolean = role.equals("user", ignoreCase = true)
    
    fun getFullName(): String {
        return if (firstName != null && lastName != null) {
            "$firstName $lastName"
        } else {
            username
        }
    }
    
    fun isOidcUser(): Boolean = keycloakId != null
    
    fun isLocalUser(): Boolean = password != null
    
    fun hasEmail(): Boolean = email != null && email.isNotBlank()
    
    fun hasFullName(): Boolean = firstName != null && lastName != null && 
        firstName.isNotBlank() && lastName.isNotBlank()
    
    fun getDisplayName(): String = getFullName()
    fun getDisplayEmail(): String = email?.takeIf { it.isNotBlank() } ?: "Sin correo"
    fun getDisplayRole(): String = role.takeIf { it.isNotBlank() } ?: "Sin rol"
    fun getDisplayStatus(): String = if (isActive) "Activo" else "Inactivo"
    fun getDisplayLastLogin(): String = lastLoginAt?.toString() ?: "Nunca"

    override fun toString(): String {
        return """
            {
                "id": $id,
                "keycloakId": "${keycloakId ?: "N/A"}",
                "username": "$username",
                "password": "${if (password != null) "********" else "N/A"}",
                "email": "${email ?: "Sin correo"}",
                "firstName": "${firstName ?: "N/A"}",
                "lastName": "${lastName ?: "N/A"}",
                "role": "$role",
                "isActive": $isActive,
                "lastLoginAt": "${lastLoginAt ?: "N/A"}",
                "createdAt": "$createdAt",
                "updatedAt": "$updatedAt",
                "isValid": ${isValid()}
            }
        """.trimIndent()
    }
}