package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api

import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserAuthDTO
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserCreateDTO
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserProfileDTO
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserUpdateDTO
import com.co.kinsoft.api.iasy_stock_api.domain.service.UserSynchronizationService
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.user.UserUseCase
import com.co.kinsoft.api.iasy_stock_api.infraestructure.helpers.JwtUtils
import com.co.kinsoft.api.iasy_stock_api.infraestructure.helpers.UserInfo
import com.co.kinsoft.api.iasy_stock_api.config.AuthProperties
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken
import org.springframework.web.bind.annotation.*
import reactor.core.publisher.Mono
import java.time.LocalDateTime

@RestController
@RequestMapping("/api/v1/auth")
class AuthController(
    private val userUseCase: UserUseCase,
    private val userSynchronizationService: UserSynchronizationService,
    private val authProperties: AuthProperties
) {
    private fun devUserInfo(): UserInfo = UserInfo(
        id = "dev-user-1",
        username = "developer",
        email = "dev@localhost",
        firstName = "Dev",
        lastName = "User",
        roles = listOf("sudo", "admin", "almacenista", "ventas", "user")
    )

    @GetMapping("/me")
    fun getCurrentUser(authentication: Authentication?): Mono<ResponseEntity<UserAuthDTO>> {
        if ((authentication == null || !authentication.isAuthenticated) && authProperties.disableSecurity) {
            return userSynchronizationService
                .syncUser(devUserInfo())
                .map { user -> ResponseEntity.ok(user.toAuthDTO()) }
        }
        val auth = authentication ?: return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build())
        return JwtUtils.getUserInfo(auth)
            .flatMap { userInfo ->
                userSynchronizationService.syncUser(userInfo)
                    .map { user ->
                        ResponseEntity.ok(user.toAuthDTO())
                    }
            }
            .onErrorResume { error ->
                Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build())
            }
    }

}

// Extension functions para convertir entre modelos
fun User.toAuthDTO(): UserAuthDTO {
    return UserAuthDTO(
        id = this.id,
        keycloakId = this.keycloakId,
        username = this.username,
        email = this.email,
        firstName = this.firstName,
        lastName = this.lastName,
        role = this.role,
        isActive = this.isActive,
        lastLoginAt = this.lastLoginAt,
        createdAt = this.createdAt,
        updatedAt = this.updatedAt
    )
}
