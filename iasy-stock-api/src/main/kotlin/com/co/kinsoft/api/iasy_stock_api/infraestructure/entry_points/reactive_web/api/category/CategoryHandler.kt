package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.category

import com.co.kinsoft.api.iasy_stock_api.domain.model.category.Category
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.category.CategoryUseCase
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class CategoryHandler(private val categoryUseCase: CategoryUseCase) {
    val logger: Logger = LoggerFactory.getLogger(CategoryHandler::class.java)

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(categoryUseCase.findAll(page, size), Category::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return categoryUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(Category::class.java)
            .flatMap { categoryUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return request.bodyToMono(Category::class.java)
            .flatMap { categoryUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")

        return categoryUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByName(request: ServerRequest): Mono<ServerResponse> {
        val name = request.queryParam("name").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(categoryUseCase.findByName(name, page, size), Category::class.java)
    }

    fun findByNameContaining(request: ServerRequest): Mono<ServerResponse> {
        val name = request.queryParam("name").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(categoryUseCase.findByNameContaining(name, page, size), Category::class.java)
    }
}