package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.user

import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.user.UserUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class UserHandler(private val userUseCase: UserUseCase) {
    val logger: Logger = LoggerFactory.getLogger(UserHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(userUseCase.findAll(page, size), User::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return userUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(User::class.java)
            .flatMap { userUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(User::class.java)
            .flatMap { userUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return userUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByUsername(request: ServerRequest): Mono<ServerResponse> {
        val username = request.queryParam("username").orElse("")
        return userUseCase.findByUsername(username)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findByEmail(request: ServerRequest): Mono<ServerResponse> {
        val email = request.queryParam("email").orElse("")
        return userUseCase.findByEmail(email)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findByRole(request: ServerRequest): Mono<ServerResponse> {
        val role = request.queryParam("role").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(userUseCase.findByRole(role, page, size), User::class.java)
    }
}