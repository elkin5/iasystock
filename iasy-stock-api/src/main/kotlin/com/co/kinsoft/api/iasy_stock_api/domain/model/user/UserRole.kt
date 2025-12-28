package com.co.kinsoft.api.iasy_stock_api.domain.model.user

/**
 * Roles disponibles en el sistema Iasy Stock
 */
enum class UserRole(val value: String, val description: String, val keycloakRoles: List<String>) {
    SUDO("sudo", "Super Usuario", listOf("sudo", "super_admin")),
    ADMIN("admin", "Administrador", listOf("admin", "administrator")),
    ALMACENISTA("almacenista", "Almacenista", listOf("almacenista", "warehouse_manager")),
    VENTAS("ventas", "Vendedor", listOf("ventas", "sales", "vendedor")),
    USER("user", "Usuario Básico", listOf("user", "default"));
    
    companion object {
        /**
         * Mapea roles de Keycloak a roles de aplicación
         */
        fun fromKeycloakRoles(keycloakRoles: List<String>): UserRole {
            // Buscar coincidencia exacta primero
            keycloakRoles.forEach { keycloakRole ->
                values().forEach { appRole ->
                    if (appRole.keycloakRoles.contains(keycloakRole.lowercase())) {
                        return appRole
                    }
                }
            }
            
            // Si no hay coincidencia, buscar por similitud
            keycloakRoles.forEach { keycloakRole ->
                when (keycloakRole.lowercase()) {
                    "admin", "administrator" -> return ADMIN
                    "sudo", "super_admin", "root" -> return SUDO
                    "almacenista", "warehouse", "inventory" -> return ALMACENISTA
                    "ventas", "sales", "vendedor" -> return VENTAS
                    "user", "default" -> return USER
                }
            }
            
            // Rol por defecto si no se encuentra coincidencia
            return USER
        }
        
        /**
         * Valida si un rol es válido
         */
        fun isValid(role: String): Boolean {
            return values().any { it.value.equals(role, ignoreCase = true) }
        }
        
        /**
         * Obtiene todos los roles válidos como lista de strings
         */
        fun getAllRoles(): List<String> {
            return values().map { it.value }
        }
        
        /**
         * Obtiene roles de aplicación para un rol específico
         */
        fun getApplicationRoles(keycloakRole: String): List<String> {
            return values().find { it.keycloakRoles.contains(keycloakRole.lowercase()) }?.keycloakRoles ?: emptyList()
        }
    }
}
