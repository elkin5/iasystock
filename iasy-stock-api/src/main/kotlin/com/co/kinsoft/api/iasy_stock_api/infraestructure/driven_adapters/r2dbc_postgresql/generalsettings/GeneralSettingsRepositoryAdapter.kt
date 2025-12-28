package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.generalsettings

import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.GeneralSettings
import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.gateway.GeneralSettingsRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Repository
class GeneralSettingsRepositoryAdapter(
    private val generalSettingsDAORepository: GeneralSettingsDAORepository,
    private val generalSettingsMapper: GeneralSettingsMapper
) : GeneralSettingsRepository {

    override fun findAll(page: Int, size: Int): Flux<GeneralSettings> {
        return generalSettingsDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { generalSettingsMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<GeneralSettings> {
        return generalSettingsDAORepository.findById(id)
            .map { generalSettingsMapper.toDomain(it) }
    }

    override fun save(generalSettings: GeneralSettings): Mono<GeneralSettings> {
        val generalSettingsDAO = generalSettingsMapper.toDAO(generalSettings)
        return generalSettingsDAORepository.save(generalSettingsDAO)
            .map { generalSettingsMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return generalSettingsDAORepository.deleteById(id)
    }

    override fun findByKey(key: String): Mono<GeneralSettings> {
        return generalSettingsDAORepository.findByKey(key)
            .map { generalSettingsMapper.toDomain(it) }
    }

    override fun findByKeyContaining(keyword: String, page: Int, size: Int): Flux<GeneralSettings> {
        return generalSettingsDAORepository.findByKeyContaining(keyword)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { generalSettingsMapper.toDomain(it) }
    }

    override fun deleteByKey(key: String): Mono<Void> {
        return generalSettingsDAORepository.deleteByKey(key)
    }
}