package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.generalsettings

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface GeneralSettingsDAORepository : ReactiveCrudRepository<GeneralSettingsDAO, Long> {
    fun findByKey(key: String): Mono<GeneralSettingsDAO>
    fun findByKeyContaining(keyword: String): Flux<GeneralSettingsDAO>
    fun deleteByKey(key: String): Mono<Void>
}