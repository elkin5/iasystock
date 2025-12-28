package com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.GeneralSettings
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface GeneralSettingsRepository {
    fun findAll(page: Int, size: Int): Flux<GeneralSettings>
    fun findById(id: Long): Mono<GeneralSettings>
    fun save(generalSettings: GeneralSettings): Mono<GeneralSettings>
    fun deleteById(id: Long): Mono<Void>

    // Métodos adicionales recomendados
    fun findByKey(key: String): Mono<GeneralSettings>
    fun findByKeyContaining(keyword: String, page: Int, size: Int): Flux<GeneralSettings>
    fun deleteByKey(key: String): Mono<Void>
}