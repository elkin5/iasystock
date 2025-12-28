package com.co.kinsoft.api.iasy_stock_api.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.reactive.CorsWebFilter
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource

@Configuration
class CorsGlobalConfig {

    @Bean
    fun corsWebFilter(): CorsWebFilter {
        val corsConfig = CorsConfiguration()
//        corsConfig.allowedOrigins = listOf("*")
        // ✅ Permite todos los orígenes localhost con cualquier puerto
        corsConfig.allowedOriginPatterns = listOf(
            "http://localhost:*",
            "http://127.0.0.1:*"
        )
//        corsConfig.allowedOrigins = listOf("https://app.iasystock.com") // para producción
        corsConfig.allowedMethods = listOf("GET", "POST", "PUT", "DELETE", "OPTIONS")
        corsConfig.allowedHeaders = listOf("*")
//        corsConfig.allowedHeaders = listOf("Authorization", "Content-Type") // para producción
        corsConfig.allowCredentials = true
        corsConfig.maxAge = 3600L

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", corsConfig)

        return CorsWebFilter(source)
    }
}