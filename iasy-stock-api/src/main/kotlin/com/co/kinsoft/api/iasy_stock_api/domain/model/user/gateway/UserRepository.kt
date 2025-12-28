package com.co.kinsoft.api.iasy_stock_api.domain.model.user.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import org.springframework.data.domain.Pageable
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface UserRepository {
    fun findAll(page: Int, size: Int): Flux<User>
    fun findById(id: Long): Mono<User>
    fun save(user: User): Mono<User>
    fun deleteById(id: Long): Mono<Void>
    fun findByUsername(username: String): Mono<User>
    fun findByEmail(email: String?): Mono<User>
    fun findByRole(role: String, page: Int, size: Int): Flux<User>
    
    // Nuevos métodos para autenticación OIDC
    fun findByKeycloakId(keycloakId: String): Mono<User>
    fun findAll(pageable: Pageable, role: String?, isActive: Boolean?): Flux<User>
    fun getUserStats(): Mono<Map<String, Any>>
}