package com.co.kinsoft.api.iasy_stock_api.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoder
import org.springframework.security.oauth2.jwt.NimbusReactiveJwtDecoder
import org.springframework.security.oauth2.jwt.JwtValidators
import org.springframework.security.oauth2.jwt.JwtClaimValidator
import org.springframework.web.reactive.function.client.WebClient

@Configuration
@ConfigurationProperties(prefix = "app.auth")
data class AuthProperties(
    var keycloakIssuer: String = "http://localhost:8080/realms/myapp",
    var jwkSetUri: String = "http://localhost:8080/realms/myapp/protocol/openid-connect/certs",
    var audience: String = "iasy-stock-app",
    var disableSecurity: Boolean = false
)

@Configuration
class AuthConfig(
    private val authProperties: AuthProperties
) {

    @Bean
    fun jwtDecoder(): ReactiveJwtDecoder {
        // Crear el decoder base con el issuer principal
        val jwtDecoder = NimbusReactiveJwtDecoder.withJwkSetUri(authProperties.jwkSetUri)
            .build()
        
        // Configurar validador personalizado que acepta múltiples issuers
        val localhostIssuer = authProperties.keycloakIssuer
        val emulatorIssuer = authProperties.keycloakIssuer.replace("localhost", "10.0.2.2")
        
        // Crear validador que acepta ambos issuers
        val multiIssuerValidator = JwtClaimValidator<String>("iss") { claim ->
            val issuer = claim?.toString()
            issuer == localhostIssuer || issuer == emulatorIssuer
        }
        
        // Usar el validador personalizado que acepta múltiples issuers
        jwtDecoder.setJwtValidator(multiIssuerValidator)
        
        return jwtDecoder
    }

    @Bean
    fun keycloakWebClient(): WebClient {
        return WebClient.builder()
            .baseUrl(authProperties.keycloakIssuer)
            .build()
    }
}
