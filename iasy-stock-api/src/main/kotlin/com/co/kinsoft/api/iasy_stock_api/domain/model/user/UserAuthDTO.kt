package com.co.kinsoft.api.iasy_stock_api.domain.model.user

import java.time.LocalDateTime

data class UserAuthDTO(
    val id: Long,
    val keycloakId: String?,
    val username: String,
    val email: String?,
    val firstName: String?,
    val lastName: String?,
    val role: String,
    val isActive: Boolean,
    val lastLoginAt: LocalDateTime?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    fun getFullName(): String {
        return if (firstName != null && lastName != null) {
            "$firstName $lastName"
        } else {
            username
        }
    }
    
    fun isAdmin(): Boolean = role.equals("admin", ignoreCase = true)
    
    fun isManager(): Boolean = role.equals("manager", ignoreCase = true) || isAdmin()
    
    fun isUser(): Boolean = role.equals("user", ignoreCase = true)
}

data class UserProfileDTO(
    val id: Long,
    val username: String,
    val email: String?,
    val firstName: String?,
    val lastName: String?,
    val role: String,
    val isActive: Boolean,
    val lastLoginAt: LocalDateTime?
) {
    fun getFullName(): String {
        return if (firstName != null && lastName != null) {
            "$firstName $lastName"
        } else {
            username
        }
    }
}

data class UserCreateDTO(
    val keycloakId: String?,
    val username: String,
    val email: String?,
    val firstName: String?,
    val lastName: String?,
    val role: String = "user"
)

data class UserUpdateDTO(
    val email: String?,
    val firstName: String?,
    val lastName: String?,
    val isActive: Boolean? = null,
    val role: String? = null
)
