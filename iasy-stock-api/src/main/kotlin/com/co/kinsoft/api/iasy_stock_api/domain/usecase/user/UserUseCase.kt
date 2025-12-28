package com.co.kinsoft.api.iasy_stock_api.domain.usecase.user

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.UserCreateDTO
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.gateway.UserRepository
import org.springframework.data.domain.Pageable
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

class UserUseCase(private val userRepository: UserRepository) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<User> =
        userRepository.findAll(page, size)

    fun findById(id: Long): Mono<User> {
        if (id <= 0) return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        return userRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("El usuario con ID $id no existe.")))
    }

    fun create(user: User): Mono<User> {
        return Mono.fromCallable {
            UserValidator.validate(user)
            user
        }.flatMap {
            userRepository.findByEmail(user.email)
                .flatMap<User> {
                    Mono.error(AlreadyExistsException("Ya existe un usuario con el email '${user.email}'"))
                }
                .switchIfEmpty(
                    userRepository.findByUsername(user.username)
                        .flatMap<User> {
                            Mono.error(AlreadyExistsException("Ya existe un usuario con el nombre de usuario '${user.username}'"))
                        }
                        .switchIfEmpty(userRepository.save(user))
                )
        }
    }

    fun update(id: Long, user: User): Mono<User> {
        if (id <= 0) return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        return Mono.fromCallable {
            UserValidator.validate(user)
            user
        }.flatMap {
            userRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("El usuario con ID $id no existe.")))
        }.flatMap { existingUser ->
            val updatedUser = existingUser.copy(
                username = user.username,
                password = user.password,
                email = user.email,
                firstName = user.firstName,
                lastName = user.lastName,
                role = user.role,
                isActive = user.isActive,
                updatedAt = LocalDateTime.now()
            )
            userRepository.save(updatedUser)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        return userRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: el usuario con ID $id no existe.")))
            .flatMap { userRepository.deleteById(id) }
    }

    fun findByUsername(username: String): Mono<User> {
        if (username.isBlank()) return Mono.error(InvalidDataException("El nombre de usuario no puede estar vacío."))
        return userRepository.findByUsername(username)
            .switchIfEmpty(Mono.error(NotFoundException("No se encontró usuario con username '$username'.")))
    }

    fun findByEmail(email: String): Mono<User> {
        if (email.isBlank()) return Mono.error(InvalidDataException("El email no puede estar vacío."))
        return userRepository.findByEmail(email)
            .switchIfEmpty(Mono.error(NotFoundException("No se encontró usuario con email '$email'.")))
    }

    fun findByRole(role: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<User> {
        if (role.isBlank()) return Flux.error(InvalidDataException("El rol no puede estar vacío."))
        return userRepository.findByRole(role, page, size)
    }

    // Nuevos métodos para autenticación OIDC

    fun findByKeycloakId(keycloakId: String): Mono<User> {
        if (keycloakId.isBlank()) return Mono.error(InvalidDataException("El Keycloak ID no puede estar vacío."))
        return userRepository.findByKeycloakId(keycloakId)
    }

    fun create(userCreateDTO: UserCreateDTO): Mono<User> {
        return Mono.fromCallable {
            UserValidator.validateCreateDTO(userCreateDTO)
            userCreateDTO
        }.flatMap { dto ->
            val user = User(
                keycloakId = dto.keycloakId,
                username = dto.username,
                email = dto.email,
                firstName = dto.firstName,
                lastName = dto.lastName,
                role = dto.role,
                isActive = true,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
            userRepository.save(user)
        }
    }

    fun update(user: User): Mono<User> {
        return Mono.fromCallable {
            UserValidator.validate(user)
            user
        }.flatMap { validatedUser ->
            userRepository.save(validatedUser)
        }
    }

    fun findAll(pageable: Pageable, role: String? = null, isActive: Boolean? = null): Flux<User> {
        return userRepository.findAll(pageable, role, isActive)
    }

    fun getUserStats(): Mono<Map<String, Any>> {
        return userRepository.getUserStats()
    }
}