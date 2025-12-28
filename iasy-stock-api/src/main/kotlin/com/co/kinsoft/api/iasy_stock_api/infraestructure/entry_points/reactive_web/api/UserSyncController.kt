package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api

import com.co.kinsoft.api.iasy_stock_api.domain.annotation.RequiresSudo
import com.co.kinsoft.api.iasy_stock_api.domain.service.UserSynchronizationService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*
import reactor.core.publisher.Mono

/**
 * Controlador para sincronización masiva de usuarios
 * Acceso: solo sudo
 */
@RestController
@RequestMapping("/api/v1/admin/user-sync")
@RequiresSudo
class UserSyncController(
    private val userSynchronizationService: UserSynchronizationService
) {

    /**
     * Sincronizar todos los usuarios de la base de datos con Keycloak
     * Acceso: solo sudo
     */
    @PostMapping("/sync-all")
    fun syncAllUsers(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return userSynchronizationService.syncAllUsers()
            .collectList()
            .map { users ->
                val response = mapOf(
                    "message" to "Sincronización completada",
                    "totalUsers" to users.size,
                    "syncedUsers" to users.map { it.username },
                    "timestamp" to System.currentTimeMillis()
                )
                ResponseEntity.ok(response)
            }
            .onErrorResume { error ->
                Mono.just(ResponseEntity.internalServerError().body(mapOf(
                    "error" to "Error en sincronización: ${error.message}",
                    "timestamp" to System.currentTimeMillis()
                )))
            }
    }

    /**
     * Obtener estadísticas de sincronización
     * Acceso: solo sudo
     */
    @GetMapping("/stats")
    fun getSyncStats(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return userSynchronizationService.getSyncStats()
            .map { stats ->
                ResponseEntity.ok(stats)
            }
    }

    /**
     * Validar consistencia entre usuarios locales y Keycloak
     * Acceso: solo sudo
     */
    @GetMapping("/validate")
    fun validateConsistency(authentication: Authentication): Mono<ResponseEntity<Map<String, Any>>> {
        return userSynchronizationService.validateConsistency()
            .map { validation ->
                ResponseEntity.ok(validation)
            }
    }

    /**
     * Sincronizar un usuario específico por Keycloak ID
     * Acceso: solo sudo
     */
    @PostMapping("/sync/{keycloakId}")
    fun syncUserByKeycloakId(
        @PathVariable keycloakId: String,
        authentication: Authentication
    ): Mono<ResponseEntity<Map<String, Any>>> {
        return userSynchronizationService.syncUserByKeycloakId(keycloakId)
            .map { user ->
                val response = mapOf(
                    "message" to "Usuario sincronizado exitosamente",
                    "user" to mapOf(
                        "id" to user.id,
                        "username" to user.username,
                        "email" to user.email,
                        "role" to user.role,
                        "keycloakId" to user.keycloakId
                    ),
                    "timestamp" to System.currentTimeMillis()
                )
                ResponseEntity.ok(response)
            }
            .onErrorResume { error ->
                Mono.just(ResponseEntity.badRequest().body(mapOf(
                    "error" to "Error al sincronizar usuario: ${error.message}",
                    "keycloakId" to keycloakId,
                    "timestamp" to System.currentTimeMillis()
                )))
            }
    }
}
