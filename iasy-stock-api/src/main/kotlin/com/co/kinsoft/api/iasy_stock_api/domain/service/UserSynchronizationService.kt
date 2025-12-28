package com.co.kinsoft.api.iasy_stock_api.domain.service

import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserRole
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.user.UserUseCase
import com.co.kinsoft.api.iasy_stock_api.infraestructure.helpers.UserInfo
import org.springframework.stereotype.Service
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Servicio para sincronización entre usuarios de Keycloak y la base de datos local
 */
@Service
class UserSynchronizationService(
    private val userUseCase: UserUseCase
) {
    
    /**
     * Sincroniza un usuario específico con Keycloak
     */
    fun syncUser(userInfo: UserInfo): Mono<User> {
        return userUseCase.findByKeycloakId(userInfo.id)
            .flatMap { existingUser ->
                // Usuario existe, actualizar datos
                updateUserFromKeycloak(existingUser, userInfo)
            }
            .switchIfEmpty(
                // Usuario no existe, crearlo
                createUserFromKeycloak(userInfo)
            )
    }
    
    /**
     * Crea un nuevo usuario desde datos de Keycloak
     */
    fun createUserFromKeycloak(userInfo: UserInfo): Mono<User> {
        val role = UserRole.fromKeycloakRoles(userInfo.roles)
        
        val userCreateDTO = com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserCreateDTO(
            keycloakId = userInfo.id,
            username = userInfo.username,
            email = userInfo.email,
            firstName = userInfo.firstName,
            lastName = userInfo.lastName,
            role = role.value
        )
        
        return userUseCase.create(userCreateDTO)
    }
    
    /**
     * Actualiza un usuario existente con datos de Keycloak
     */
    fun updateUserFromKeycloak(existingUser: User, userInfo: UserInfo): Mono<User> {
        val newRole = UserRole.fromKeycloakRoles(userInfo.roles)
        
        val updatedUser = existingUser.copy(
            username = userInfo.username,
            email = userInfo.email,
            firstName = userInfo.firstName,
            lastName = userInfo.lastName,
            role = newRole.value, // Actualizar rol si cambió en Keycloak
            lastLoginAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        return userUseCase.update(updatedUser)
    }
    
    /**
     * Sincroniza todos los usuarios de la base de datos con Keycloak
     * (Para migración masiva)
     */
    fun syncAllUsers(): Flux<User> {
        return userUseCase.findAll()
            .flatMap { user ->
                if (user.isOidcUser()) {
                    // Solo sincronizar usuarios OIDC
                    syncUserByKeycloakId(user.keycloakId!!)
                } else {
                    Mono.just(user)
                }
            }
    }
    
    /**
     * Sincroniza un usuario específico por su Keycloak ID
     */
    fun syncUserByKeycloakId(keycloakId: String): Mono<User> {
        return userUseCase.findByKeycloakId(keycloakId)
            .flatMap { user ->
                // Aquí podrías hacer una llamada a Keycloak Admin API
                // para obtener los datos más recientes del usuario
                // Por ahora, solo actualizamos el lastLoginAt
                val updatedUser = user.copy(
                    lastLoginAt = LocalDateTime.now(),
                    updatedAt = LocalDateTime.now()
                )
                userUseCase.update(updatedUser)
            }
    }
    
    /**
     * Obtiene estadísticas de sincronización
     */
    fun getSyncStats(): Mono<Map<String, Any>> {
        return userUseCase.findAll()
            .collectList()
            .map { users ->
                val totalUsers = users.size
                val oidcUsers = users.count { it.isOidcUser() }
                val localUsers = users.count { it.isLocalUser() }
                val usersByRole = users.groupBy { it.role }
                
                mapOf(
                    "totalUsers" to totalUsers,
                    "oidcUsers" to oidcUsers,
                    "localUsers" to localUsers,
                    "usersByRole" to usersByRole.mapValues { it.value.size },
                    "lastSync" to LocalDateTime.now()
                )
            }
    }
    
    /**
     * Valida la consistencia entre usuarios locales y Keycloak
     */
    fun validateConsistency(): Mono<Map<String, Any>> {
        return userUseCase.findAll()
            .collectList()
            .map { users ->
                val inconsistencies = mutableListOf<String>()
                
                users.forEach { user ->
                    if (user.isOidcUser() && user.keycloakId.isNullOrBlank()) {
                        inconsistencies.add("Usuario ${user.username} marcado como OIDC pero sin keycloakId")
                    }
                    
                    if (!UserRole.isValid(user.role)) {
                        inconsistencies.add("Usuario ${user.username} tiene rol inválido: ${user.role}")
                    }
                }
                
                mapOf(
                    "totalUsers" to users.size,
                    "inconsistencies" to inconsistencies,
                    "isConsistent" to inconsistencies.isEmpty()
                )
            }
    }
}
