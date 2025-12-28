package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.user

import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import com.co.kinsoft.api.iasy_stock_api.domain.model.user.gateway.UserRepository
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Repository
class UserRepositoryAdapter(
    private val userDAORepository: UserDAORepository,
    private val userMapper: UserMapper
) : UserRepository {

    override fun findAll(page: Int, size: Int): Flux<User> {
        return userDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { userMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<User> {
        return userDAORepository.findById(id)
            .map { userMapper.toDomain(it) }
    }

    override fun save(user: User): Mono<User> {
        val userDAO = userMapper.toDAO(user)
        return userDAORepository.save(userDAO)
            .map { userMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return userDAORepository.deleteById(id)
    }

    override fun findByUsername(username: String): Mono<User> {
        return userDAORepository.findByUsername(username)
            .map { userMapper.toDomain(it) }
    }

    override fun findByEmail(email: String?): Mono<User> {
        return userDAORepository.findByEmail(email)
            .map { userMapper.toDomain(it) }
    }

    override fun findByRole(role: String, page: Int, size: Int): Flux<User> {
        return userDAORepository.findByRole(role)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { userMapper.toDomain(it) }
    }

    // Nuevos métodos para autenticación OIDC
    override fun findByKeycloakId(keycloakId: String): Mono<User> {
        return userDAORepository.findByKeycloakId(keycloakId)
            .map { userMapper.toDomain(it) }
    }

    override fun findAll(pageable: Pageable, role: String?, isActive: Boolean?): Flux<User> {
        return when {
            role != null && isActive != null -> {
                userDAORepository.findByRoleAndIsActive(role, isActive)
                    .skip(pageable.offset)
                    .take(pageable.pageSize.toLong())
                    .map { userMapper.toDomain(it) }
            }
            role != null -> {
                userDAORepository.findByRole(role)
                    .skip(pageable.offset)
                    .take(pageable.pageSize.toLong())
                    .map { userMapper.toDomain(it) }
            }
            isActive != null -> {
                userDAORepository.findByIsActive(isActive)
                    .skip(pageable.offset)
                    .take(pageable.pageSize.toLong())
                    .map { userMapper.toDomain(it) }
            }
            else -> {
                userDAORepository.findAll()
                    .skip(pageable.offset)
                    .take(pageable.pageSize.toLong())
                    .map { userMapper.toDomain(it) }
            }
        }
    }

    override fun getUserStats(): Mono<Map<String, Any>> {
        return userDAORepository.findAll()
            .collectList()
            .map { users ->
                val totalUsers = users.size
                val activeUsers = users.count { it.isActive }
                val inactiveUsers = totalUsers - activeUsers
                val adminUsers = users.count { it.role.equals("admin", ignoreCase = true) }
                val managerUsers = users.count { it.role.equals("manager", ignoreCase = true) }
                val regularUsers = users.count { it.role.equals("user", ignoreCase = true) }
                
                mapOf(
                    "totalUsers" to totalUsers,
                    "activeUsers" to activeUsers,
                    "inactiveUsers" to inactiveUsers,
                    "adminUsers" to adminUsers,
                    "managerUsers" to managerUsers,
                    "regularUsers" to regularUsers
                )
            }
    }
}