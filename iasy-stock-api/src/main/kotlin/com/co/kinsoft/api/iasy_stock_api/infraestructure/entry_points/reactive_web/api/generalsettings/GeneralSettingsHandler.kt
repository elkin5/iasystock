package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.generalsettings

import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.GeneralSettings
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.generalsettings.GeneralSettingsUseCase
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.server.ServerRequest
import org.springframework.web.reactive.function.server.ServerResponse
import reactor.core.publisher.Mono

@Component
class GeneralSettingsHandler(private val generalSettingsUseCase: GeneralSettingsUseCase) {

    fun findAll(request: ServerRequest): Mono<ServerResponse> {
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok().body(generalSettingsUseCase.findAll(page, size), GeneralSettings::class.java)
    }

    fun findById(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")
        return generalSettingsUseCase.findById(id)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun create(request: ServerRequest): Mono<ServerResponse> {
        return request.bodyToMono(GeneralSettings::class.java)
            .flatMap { generalSettingsUseCase.create(it) }
            .flatMap { ServerResponse.status(HttpStatus.CREATED).bodyValue(it) }
    }

    fun update(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")
        return request.bodyToMono(GeneralSettings::class.java)
            .flatMap { generalSettingsUseCase.update(id, it) }
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun delete(request: ServerRequest): Mono<ServerResponse> {
        val id = request.pathVariable("id").toLongOrNull()
            ?: return ServerResponse.badRequest().bodyValue("ID inválido.")
        return generalSettingsUseCase.delete(id)
            .then(ServerResponse.noContent().build())
    }

    fun findByKey(request: ServerRequest): Mono<ServerResponse> {
        val key = request.queryParam("key").orElse("")
        return generalSettingsUseCase.findByKey(key)
            .flatMap { ServerResponse.ok().bodyValue(it) }
    }

    fun findByKeyContaining(request: ServerRequest): Mono<ServerResponse> {
        val keyword = request.queryParam("keyword").orElse("")
        val page = request.queryParam("page").map { it.toInt() }.orElse(0)
        val size = request.queryParam("size").map { it.toInt() }.orElse(10)
        return ServerResponse.ok()
            .body(generalSettingsUseCase.findByKeyContaining(keyword, page, size), GeneralSettings::class.java)
    }

    fun deleteByKey(request: ServerRequest): Mono<ServerResponse> {
        val key = request.queryParam("key").orElse("")
        return generalSettingsUseCase.deleteByKey(key)
            .then(ServerResponse.noContent().build())
    }
}