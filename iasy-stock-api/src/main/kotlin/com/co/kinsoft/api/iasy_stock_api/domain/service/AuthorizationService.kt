package com.co.kinsoft.api.iasy_stock_api.domain.service

import org.springframework.security.core.Authentication
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono

/**
 * Servicio de autorización para manejar permisos basados en roles
 */
@Service
class AuthorizationService {

    /**
     * Verifica si el usuario tiene un rol específico
     */
    fun hasRole(authentication: Authentication, role: String): Boolean {
        return if (authentication.principal is Jwt) {
            val jwt = authentication.principal as Jwt
            @Suppress("UNCHECKED_CAST")
            val roles = jwt.getClaim<List<String>>("roles") as? List<String> ?: emptyList()
            roles.contains(role.lowercase())
        } else {
            false
        }
    }

    /**
     * Verifica si el usuario tiene alguno de los roles especificados
     */
    fun hasAnyRole(authentication: Authentication, roles: List<String>): Boolean {
        return if (authentication.principal is Jwt) {
            val jwt = authentication.principal as Jwt
            @Suppress("UNCHECKED_CAST")
            val userRoles = jwt.getClaim<List<String>>("roles") as? List<String> ?: emptyList()
            roles.any { role -> userRoles.contains(role.lowercase()) }
        } else {
            false
        }
    }

    /**
     * Verifica si el usuario es super usuario (sudo)
     */
    fun isSudo(authentication: Authentication): Boolean {
        return hasRole(authentication, "sudo")
    }

    /**
     * Verifica si el usuario es administrador
     */
    fun isAdmin(authentication: Authentication): Boolean {
        return hasRole(authentication, "admin")
    }

    /**
     * Verifica si el usuario es almacenista
     */
    fun isAlmacenista(authentication: Authentication): Boolean {
        return hasRole(authentication, "almacenista")
    }

    /**
     * Verifica si el usuario es vendedor
     */
    fun isVentas(authentication: Authentication): Boolean {
        return hasRole(authentication, "ventas")
    }

    /**
     * Verifica si el usuario puede acceder a gestión de inventario
     */
    fun canAccessInventory(authentication: Authentication): Boolean {
        return isSudo(authentication) || isAdmin(authentication) || isAlmacenista(authentication)
    }

    /**
     * Verifica si el usuario puede acceder a gestión de ventas
     */
    fun canAccessSales(authentication: Authentication): Boolean {
        return isSudo(authentication) || isAdmin(authentication) || isVentas(authentication)
    }

    /**
     * Verifica si el usuario puede acceder a reportes
     */
    fun canAccessReports(authentication: Authentication): Boolean {
        return isSudo(authentication) || isAdmin(authentication)
    }

    /**
     * Verifica si el usuario puede acceder a auditoría
     */
    fun canAccessAudit(authentication: Authentication): Boolean {
        return isSudo(authentication)
    }

    /**
     * Verifica si el usuario puede gestionar usuarios
     */
    fun canManageUsers(authentication: Authentication): Boolean {
        return isSudo(authentication) || isAdmin(authentication)
    }

    /**
     * Verifica si el usuario puede modificar stock
     */
    fun canModifyStock(authentication: Authentication): Boolean {
        return isSudo(authentication) || isAdmin(authentication) || isAlmacenista(authentication)
    }

    /**
     * Verifica si el usuario puede crear ventas
     */
    fun canCreateSales(authentication: Authentication): Boolean {
        return isSudo(authentication) || isAdmin(authentication) || isVentas(authentication)
    }

    /**
     * Verifica si el usuario puede consultar stock disponible
     */
    fun canViewStock(authentication: Authentication): Boolean {
        // Todos los roles pueden ver stock
        return true
    }

    /**
     * Obtiene los roles del usuario autenticado
     */
    fun getUserRoles(authentication: Authentication): List<String> {
        return if (authentication.principal is Jwt) {
            val jwt = authentication.principal as Jwt
            @Suppress("UNCHECKED_CAST")
            jwt.getClaim<List<String>>("roles") as? List<String> ?: emptyList()
        } else {
            emptyList()
        }
    }

    /**
     * Obtiene el ID del usuario autenticado
     */
    fun getUserId(authentication: Authentication): String? {
        return if (authentication.principal is Jwt) {
            val jwt = authentication.principal as Jwt
            jwt.subject
        } else {
            null
        }
    }

    /**
     * Obtiene el nombre de usuario autenticado
     */
    fun getUsername(authentication: Authentication): String? {
        return if (authentication.principal is Jwt) {
            val jwt = authentication.principal as Jwt
            jwt.getClaimAsString("preferred_username")
        } else {
            null
        }
    }

    /**
     * Obtiene el email del usuario autenticado
     */
    fun getEmail(authentication: Authentication): String? {
        return if (authentication.principal is Jwt) {
            val jwt = authentication.principal as Jwt
            jwt.getClaimAsString("email")
        } else {
            null
        }
    }

    /**
     * Verifica permisos de manera reactiva
     */
    fun hasRoleReactive(authentication: Mono<Authentication>, role: String): Mono<Boolean> {
        return authentication.map { hasRole(it, role) }
    }

    /**
     * Verifica permisos de inventario de manera reactiva
     */
    fun canAccessInventoryReactive(authentication: Mono<Authentication>): Mono<Boolean> {
        return authentication.map { canAccessInventory(it) }
    }

    /**
     * Verifica permisos de ventas de manera reactiva
     */
    fun canAccessSalesReactive(authentication: Mono<Authentication>): Mono<Boolean> {
        return authentication.map { canAccessSales(it) }
    }
}
