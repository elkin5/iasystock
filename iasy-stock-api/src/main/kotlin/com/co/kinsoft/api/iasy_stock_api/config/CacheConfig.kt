package com.co.kinsoft.api.iasy_stock_api.config

import com.github.benmanes.caffeine.cache.Caffeine
import org.springframework.cache.CacheManager
import org.springframework.cache.annotation.EnableCaching
import org.springframework.cache.caffeine.CaffeineCacheManager
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.util.concurrent.TimeUnit

/**
 * Configuración de caché con Caffeine para optimizar:
 * - Embeddings de OpenAI (costoso en tiempo y $)
 * - Esquema de base de datos (raramente cambia)
 * - Análisis de intención recurrentes
 */
@Configuration
@EnableCaching
class CacheConfig {

    /**
     * Configuración de CacheManager con Caffeine
     *
     * Estrategia:
     * - embeddings: 1000 entradas, 6 horas TTL (embeddings son costosos)
     * - database-schema: 100 entradas, 12 horas TTL (raramente cambia)
     * - intent-analysis: 500 entradas, 1 hora TTL (balance entre frescura y rendimiento)
     */
    @Bean
    fun cacheManager(): CacheManager {
        val cacheManager = CaffeineCacheManager()

        // Habilitar modo asíncrono para soporte de programación reactiva (Mono/Flux)
        cacheManager.setAsyncCacheMode(true)

        // Configuración por defecto para todos los cachés
        cacheManager.setCaffeine(
            Caffeine.newBuilder()
                .maximumSize(1000)
                .expireAfterWrite(1, TimeUnit.HOURS)
                .recordStats() // Para métricas de caché
        )

        return cacheManager
    }

    /**
     * Caché específico para embeddings de OpenAI
     * - Alta capacidad (1000 entradas)
     * - TTL largo (6 horas) porque los embeddings son determinísticos
     * - Stats habilitado para monitoreo
     */
    @Bean
    fun embeddingsCache(): com.github.benmanes.caffeine.cache.Cache<String, List<Float>> {
        return Caffeine.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(6, TimeUnit.HOURS)
            .recordStats()
            .build()
    }

    /**
     * Caché para esquema de base de datos
     * - Capacidad moderada (100 entradas)
     * - TTL muy largo (12 horas) porque el esquema raramente cambia
     */
    @Bean
    fun databaseSchemaCache(): com.github.benmanes.caffeine.cache.Cache<String, String> {
        return Caffeine.newBuilder()
            .maximumSize(100)
            .expireAfterWrite(12, TimeUnit.HOURS)
            .recordStats()
            .build()
    }
}
