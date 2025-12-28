package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.person

import com.co.kinsoft.api.iasy_stock_api.domain.model.person.Person
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.person.PersonUseCase
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class PersonHandler(private val personUseCase: PersonUseCase) {

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(personUseCase.findAll(page, size), Person::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return personUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Person::class.java)
            .flatMap { personUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Person::class.java)
            .flatMap { personUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return personUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByName(request: ServerRequest): Mono<ServerResponse> {
        val name = request.queryParam("name").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(personUseCase.findByName(name, page, size), Person::class.java)
    }

    fun findByIdentification(request: ServerRequest): Mono<ServerResponse> {
        val identification = request.queryParam("identification").map { it.toLongOrNull() }.orElse(null)
            ?: return ServerResponse.badRequest().bodyValue("Identificación inválida.")

        return personUseCase.findByIdentification(identification)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findByType(request: ServerRequest): Mono<ServerResponse> {
        val type = request.queryParam("type").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(personUseCase.findByType(type, page, size), Person::class.java)
    }

    fun findByEmail(request: ServerRequest): Mono<ServerResponse> {
        val email = request.queryParam("email").orElse("")
        return personUseCase.findByEmail(email)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findByNameContaining(request: ServerRequest): Mono<ServerResponse> {
        val keyword = request.queryParam("keyword").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(personUseCase.findByNameContaining(keyword, page, size), Person::class.java)
    }
}