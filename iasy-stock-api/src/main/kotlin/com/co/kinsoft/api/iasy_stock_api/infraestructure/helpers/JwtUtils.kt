package com.co.kinsoft.api.iasy_stock_api.infraestructure.helpers

import org.springframework.security.core.Authentication
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken
import reactor.core.publisher.Mono

object JwtUtils {

    fun getUserId(authentication: Authentication): Mono<String> {
        return when (authentication) {
            is JwtAuthenticationToken -> {
                val jwt = authentication.token as Jwt
                Mono.just(jwt.subject ?: "")
            }
            else -> Mono.empty()
        }
    }

    fun getUsername(authentication: Authentication): Mono<String> {
        return when (authentication) {
            is JwtAuthenticationToken -> {
                val jwt = authentication.token as Jwt
                val username = jwt.getClaimAsString("preferred_username") 
                    ?: jwt.getClaimAsString("email")
                    ?: jwt.subject
                    ?: ""
                Mono.just(username)
            }
            else -> Mono.empty()
        }
    }

    fun getEmail(authentication: Authentication): Mono<String> {
        return when (authentication) {
            is JwtAuthenticationToken -> {
                val jwt = authentication.token as Jwt
                Mono.just(jwt.getClaimAsString("email") ?: "")
            }
            else -> Mono.empty()
        }
    }

    fun getFirstName(authentication: Authentication): Mono<String> {
        return when (authentication) {
            is JwtAuthenticationToken -> {
                val jwt = authentication.token as Jwt
                Mono.just(jwt.getClaimAsString("given_name") ?: "")
            }
            else -> Mono.empty()
        }
    }

    fun getLastName(authentication: Authentication): Mono<String> {
        return when (authentication) {
            is JwtAuthenticationToken -> {
                val jwt = authentication.token as Jwt
                Mono.just(jwt.getClaimAsString("family_name") ?: "")
            }
            else -> Mono.empty()
        }
    }

    fun getRoles(authentication: Authentication): Mono<List<String>> {
        return when (authentication) {
            is JwtAuthenticationToken -> {
                val jwt = authentication.token as Jwt
                val realmAccess = jwt.getClaimAsMap("realm_access")
                val roles = realmAccess?.get("roles") as? List<String> ?: emptyList()
                Mono.just(roles)
            }
            else -> Mono.just(emptyList())
        }
    }

    fun hasRole(authentication: Authentication, role: String): Mono<Boolean> {
        return getRoles(authentication)
            .map { roles -> roles.any { it.equals(role, ignoreCase = true) } }
    }

    fun isAdmin(authentication: Authentication): Mono<Boolean> {
        return Mono.just(authentication.authorities.any { 
            it.authority == "ROLE_ADMIN" || it.authority == "ROLE_SUDO" 
        })
    }

    fun isManager(authentication: Authentication): Mono<Boolean> {
        return hasRole(authentication, "manager")
    }

    fun getUserInfo(authentication: Authentication): Mono<UserInfo> {
        return getUserId(authentication)
            .zipWith(getUsername(authentication))
            .zipWith(getEmail(authentication))
            .zipWith(getFirstName(authentication))
            .zipWith(getLastName(authentication))
            .zipWith(getRoles(authentication))
            .map { tuple ->
                val id = tuple.t1.t1.t1.t1.t1
                val username = tuple.t1.t1.t1.t1.t2
                val email = tuple.t1.t1.t1.t2
                val firstName = tuple.t1.t1.t2
                val lastName = tuple.t1.t2
                val roles = tuple.t2
                UserInfo(
                    id = id,
                    username = username,
                    email = email,
                    firstName = firstName,
                    lastName = lastName,
                    roles = roles
                )
            }
    }
}

data class UserInfo(
    val id: String,
    val username: String,
    val email: String,
    val firstName: String,
    val lastName: String,
    val roles: List<String>
)
