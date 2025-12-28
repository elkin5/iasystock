package com.co.kinsoft.api.iasy_stock_api.domain.usecase.generalsettings

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.GeneralSettings
import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.gateway.GeneralSettingsRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

class GeneralSettingsUseCase(private val generalSettingsRepository: GeneralSettingsRepository) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<GeneralSettings> =
        generalSettingsRepository.findAll(page, size)

    fun findById(id: Long): Mono<GeneralSettings> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return generalSettingsRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La configuración con ID $id no existe.")))
    }

    fun create(generalSettings: GeneralSettings): Mono<GeneralSettings> {
        return Mono.fromCallable {
            GeneralSettingsValidator.validate(generalSettings)
            generalSettings
        }.flatMap {
            generalSettingsRepository.findByKey(it.key)
                .hasElement()
                .flatMap { exists ->
                    if (exists) {
                        Mono.error(AlreadyExistsException("Ya existe una configuración con la clave '${generalSettings.key}'"))
                    } else {
                        generalSettingsRepository.save(generalSettings)
                    }
                }
        }
    }

    fun update(id: Long, generalSettings: GeneralSettings): Mono<GeneralSettings> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            GeneralSettingsValidator.validate(generalSettings)
            generalSettings
        }.flatMap {
            generalSettingsRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("La configuración con ID $id no existe.")))
        }.flatMap { existingSettings ->
            val updatedSettings = existingSettings.copy(
                key = generalSettings.key,
                value = generalSettings.value,
                description = generalSettings.description
            )
            generalSettingsRepository.save(updatedSettings)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return generalSettingsRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: la configuración con ID $id no existe.")))
            .flatMap { generalSettingsRepository.deleteById(id) }
    }

    fun findByKey(key: String): Mono<GeneralSettings> {
        if (key.isBlank()) {
            return Mono.error(InvalidDataException("La clave no puede estar en blanco."))
        }
        return generalSettingsRepository.findByKey(key)
            .switchIfEmpty(Mono.error(NotFoundException("La configuración con clave '$key' no existe.")))
    }

    fun findByKeyContaining(keyword: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<GeneralSettings> {
        if (keyword.isBlank()) {
            return Flux.error(InvalidDataException("El texto de búsqueda no puede estar en blanco."))
        }
        return generalSettingsRepository.findByKeyContaining(keyword, page, size)
    }

    fun deleteByKey(key: String): Mono<Void> {
        if (key.isBlank()) {
            return Mono.error(InvalidDataException("La clave no puede estar en blanco."))
        }
        return generalSettingsRepository.findByKey(key)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: la configuración con clave '$key' no existe.")))
            .flatMap { generalSettingsRepository.deleteByKey(key) }
    }
}