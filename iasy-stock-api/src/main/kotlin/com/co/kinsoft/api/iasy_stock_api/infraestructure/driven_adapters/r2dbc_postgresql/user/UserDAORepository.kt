package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.user

import org.springframework.data.domain.Pageable
import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface UserDAORepository : ReactiveCrudRepository<UserDAO, Long> {
    fun findByUsername(username: String): Mono<UserDAO>
    fun findByEmail(email: String?): Mono<UserDAO>
    fun findByRole(role: String): Flux<UserDAO>
    
    // Nuevos métodos para autenticación OIDC
    fun findByKeycloakId(keycloakId: String): Mono<UserDAO>
    fun findByRoleAndIsActive(role: String, isActive: Boolean): Flux<UserDAO>
    fun findByIsActive(isActive: Boolean): Flux<UserDAO>
}