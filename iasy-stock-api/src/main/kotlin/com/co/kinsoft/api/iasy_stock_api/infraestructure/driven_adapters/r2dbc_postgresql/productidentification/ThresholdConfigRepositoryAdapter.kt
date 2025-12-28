package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.IdentificationThresholdConfig
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ThresholdConfigRepository
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

/**
 * Adaptador de repositorio para configuraciones de umbrales de identificación
 * Implementa el puerto ThresholdConfigRepository usando R2DBC PostgreSQL
 * (Arquitectura Hexagonal - Adaptador)
 */
@Repository
class ThresholdConfigRepositoryAdapter(
    private val thresholdConfigDAORepository: ProductIdentificationThresholdConfigDAORepository
) : ThresholdConfigRepository {

    private val logger: Logger = LoggerFactory.getLogger(ThresholdConfigRepositoryAdapter::class.java)

    override fun save(config: IdentificationThresholdConfig): Mono<IdentificationThresholdConfig> {
        logger.debug("Guardando configuración de umbrales, versión: ${config.modelVersion}")

        return Mono.just(config)
            .map { it.toDAO() }
            .flatMap { thresholdConfigDAORepository.save(it) }
            .map { it.toDomain() }
            .doOnSuccess { saved ->
                logger.info("✅ Configuración guardada: ID ${saved.configId}, versión ${saved.modelVersion}")
            }
            .doOnError { error ->
                logger.error("❌ Error guardando configuración: ${error.message}", error)
            }
    }

    override fun findById(configId: Long): Mono<IdentificationThresholdConfig> {
        logger.debug("Buscando configuración por ID: $configId")

        return thresholdConfigDAORepository.findById(configId)
            .map { it.toDomain() }
            .doOnNext { logger.debug("Configuración encontrada: ID ${it.configId}") }
    }

    override fun getActiveConfig(): Mono<IdentificationThresholdConfig> {
        logger.debug("Obteniendo configuración activa")

        return thresholdConfigDAORepository.findActiveConfig()
            .map { it.toDomain() }
            .doOnNext { config ->
                logger.debug("Configuración activa: versión ${config.modelVersion}, accuracy ${config.accuracy}")
            }
            .switchIfEmpty(
                Mono.defer {
                    logger.warn("⚠️ No hay configuración activa, creando configuración por defecto")
                    createDefaultConfig()
                }
            )
    }

    override fun findAll(): Flux<IdentificationThresholdConfig> {
        logger.debug("Buscando todas las configuraciones")

        return thresholdConfigDAORepository.findAll()
            .map { it.toDomain() }
    }

    override fun findByModelVersion(modelVersion: String): Flux<IdentificationThresholdConfig> {
        logger.debug("Buscando configuraciones por versión: $modelVersion")

        return thresholdConfigDAORepository.findByModelVersion(modelVersion)
            .map { it.toDomain() }
            .flux()
    }

    override fun findActiveConfigs(): Flux<IdentificationThresholdConfig> {
        logger.debug("Buscando configuraciones activas")

        return thresholdConfigDAORepository.findActiveConfig()
            .map { it.toDomain() }
            .flux()
    }

    override fun deactivateAllExcept(configId: Long): Mono<Void> {
        logger.debug("Desactivando todas las configuraciones excepto: $configId")

        return thresholdConfigDAORepository.deactivateAllExcept(configId)
            .doOnSuccess {
                logger.info("✅ Configuraciones desactivadas excepto $configId")
            }
            .doOnError { error ->
                logger.error("❌ Error desactivando configuraciones: ${error.message}", error)
            }
            .then()
    }

    override fun findBestConfig(): Mono<IdentificationThresholdConfig> {
        logger.debug("Buscando mejor configuración (mayor accuracy)")

        return thresholdConfigDAORepository.findBestConfig()
            .map { it.toDomain() }
            .doOnNext { config ->
                logger.debug("Mejor configuración: versión ${config.modelVersion}, accuracy ${config.accuracy}")
            }
    }

    override fun findAllOrderedByAccuracy(): Flux<IdentificationThresholdConfig> {
        logger.debug("Buscando configuraciones ordenadas por accuracy")

        return thresholdConfigDAORepository.findAllOrderedByAccuracy()
            .map { it.toDomain() }
    }

    override fun deleteById(configId: Long): Mono<Void> {
        logger.debug("Eliminando configuración ID: $configId")

        return thresholdConfigDAORepository.deleteById(configId)
            .doOnSuccess {
                logger.info("✅ Configuración $configId eliminada")
            }
            .doOnError { error ->
                logger.error("❌ Error eliminando configuración $configId: ${error.message}", error)
            }
    }

    override fun activateConfig(configId: Long): Mono<IdentificationThresholdConfig> {
        logger.info("Activando configuración $configId")

        return findById(configId)
            .flatMap { config ->
                // Primero desactivar todas las demás
                deactivateAllExcept(configId)
                    .then(Mono.just(config))
            }
            .flatMap { config ->
                // Luego activar la configuración seleccionada
                val updatedConfig = config.copy(
                    isActive = true,
                    updatedAt = LocalDateTime.now()
                )
                save(updatedConfig)
            }
            .doOnSuccess { activated ->
                logger.info("✅ Configuración ${activated.configId} activada correctamente")
            }
    }

    /**
     * Crea configuración por defecto si no existe ninguna activa
     */
    private fun createDefaultConfig(): Mono<IdentificationThresholdConfig> {
        logger.info("Creando configuración por defecto")

        val defaultConfig = IdentificationThresholdConfig(
            modelVersion = "1.0",
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )

        return save(defaultConfig)
            .doOnSuccess {
                logger.info("✅ Configuración por defecto creada y activada")
            }
    }
}
