package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api

import com.co.kinsoft.api.iasy_stock_api.domain.annotation.RequiresSudo
import com.co.kinsoft.api.iasy_stock_api.domain.service.AuthorizationService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*
import reactor.core.publisher.Mono

/**
 * Controlador para funciones de super usuario
 * Acceso: solo sudo
 */
@RestController
@RequestMapping("/api/v1/sudo")
@RequiresSudo
class SudoController(
    private val authorizationService: AuthorizationService
) {

    /**
     * Obtener configuración del sistema
     * Acceso: solo sudo
     */
    @GetMapping("/config")
    fun getSystemConfig(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Configuración del sistema obtenida",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication)
        )))
    }

    /**
     * Actualizar configuración del sistema
     * Acceso: solo sudo
     */
    @PutMapping("/config")
    fun updateSystemConfig(
        @RequestBody config: Map<String, Any>,
        authentication: Authentication
    ): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Configuración del sistema actualizada",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication),
            "config" to config
        )))
    }

    /**
     * Obtener logs de auditoría
     * Acceso: solo sudo
     */
    @GetMapping("/audit/logs")
    fun getAuditLogs(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Logs de auditoría obtenidos",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication)
        )))
    }

    /**
     * Obtener estadísticas del sistema
     * Acceso: solo sudo
     */
    @GetMapping("/system/stats")
    fun getSystemStats(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Estadísticas del sistema obtenidas",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication)
        )))
    }

    /**
     * Realizar backup del sistema
     * Acceso: solo sudo
     */
    @PostMapping("/backup")
    fun createBackup(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Backup del sistema creado",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication)
        )))
    }

    /**
     * Restaurar sistema desde backup
     * Acceso: solo sudo
     */
    @PostMapping("/restore")
    fun restoreFromBackup(
        @RequestBody backupInfo: Map<String, Any>,
        authentication: Authentication
    ): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Sistema restaurado desde backup",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication),
            "backup" to backupInfo
        )))
    }

    /**
     * Obtener información de roles y permisos
     * Acceso: solo sudo
     */
    @GetMapping("/roles")
    fun getRolesInfo(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return Mono.just(ResponseEntity.ok(mapOf(
            "message" to "Información de roles obtenida",
            "user" to (authorizationService.getUsername(authentication) ?: "unknown"),
            "roles" to authorizationService.getUserRoles(authentication),
            "availableRoles" to listOf("sudo", "admin", "almacenista", "ventas")
        )))
    }
}

