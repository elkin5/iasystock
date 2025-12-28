package com.co.kinsoft.api.iasy_stock_api.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity
import org.springframework.security.config.web.server.ServerHttpSecurity
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoder
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoders
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter
import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverterAdapter
import org.springframework.security.web.server.SecurityWebFilterChain
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.reactive.CorsConfigurationSource
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource

@Configuration
@EnableWebFluxSecurity
class SecurityConfig(
    private val authProperties: AuthProperties,
    private val jwtDecoder: ReactiveJwtDecoder
) {

    @Bean
    fun springSecurityFilterChain(http: ServerHttpSecurity): SecurityWebFilterChain {
        // Verificar si la seguridad está desactivada
        if (authProperties.disableSecurity) {
            println("🔓 SEGURIDAD DESACTIVADA - Configurando endpoints públicos")
            return http
                .csrf { it.disable() }
                .cors { it.configurationSource(corsConfigurationSource()) }
                .httpBasic { it.disable() }
                .formLogin { it.disable() }
                .anonymous { }
                .authorizeExchange { exchanges ->
                    exchanges.anyExchange().permitAll()
                }
                .build()
        }

        return http
            .csrf { it.disable() }
            .cors { it.configurationSource(corsConfigurationSource()) }
            .authorizeExchange { exchanges ->
                exchanges
                    // Endpoints públicos
                    .pathMatchers(
                        "/actuator/**",
                        "/api/v1/public/**",
                        "/api/images/proxy"  // Proxy de imágenes debe ser público para evitar problemas de autenticación
                    ).permitAll()
                    // Endpoint /me requiere autenticación
                    .pathMatchers("/api/v1/auth/me").authenticated()
                    .pathMatchers("/api/v1/auth/profile").authenticated()
                    .pathMatchers("/api/v1/auth/sync").authenticated()
                    .pathMatchers("/api/v1/auth/roles").authenticated()
                    // Otros endpoints de auth pueden ser públicos si es necesario
                    .pathMatchers("/api/v1/auth/**").permitAll()
                    // Endpoints de super usuario (sudo)
                    .pathMatchers("/api/v1/sudo/**").hasRole("SUDO")
                    // Endpoints de administración (sudo y admin)
                    .pathMatchers("/api/v1/admin/**").hasAnyRole("SUDO", "ADMIN")
                    // Endpoints de inventario (sudo, admin, almacenista)
                    .pathMatchers("/api/v1/inventory/**").hasAnyRole("SUDO", "ADMIN", "ALMACENISTA")
                    // Endpoints de ventas (sudo, admin, ventas)
                    .pathMatchers("/api/v1/sales/**").hasAnyRole("SUDO", "ADMIN", "VENTAS")
                    // Endpoints de reportes (sudo, admin)
                    .pathMatchers("/api/v1/reports/**").hasAnyRole("SUDO", "ADMIN")
                    // Endpoints de auditoría (solo sudo)
                    .pathMatchers("/api/v1/audit/**").hasRole("SUDO")
                    // Endpoints de notificaciones (todos los roles autenticados)
                    .pathMatchers("/api/v1/notifications/**").authenticated()
                    // Resto de endpoints requieren autenticación
                    .pathMatchers("/api/v1/**").authenticated()
                    .anyExchange().authenticated()
            }
            .oauth2ResourceServer { oauth2 ->
                oauth2.jwt { jwt ->
                    jwt.jwtDecoder(jwtDecoder)
                        .jwtAuthenticationConverter(jwtAuthenticationConverter())
                }
            }
            .build()
    }


    @Bean
    fun jwtAuthenticationConverter(): ReactiveJwtAuthenticationConverterAdapter {
        val converter = JwtAuthenticationConverter()
        converter.setJwtGrantedAuthoritiesConverter { jwt ->
            // ✅ CORRECCIÓN: Extraer roles de realm_access (formato estándar de Keycloak)
            val realmAccess = jwt.getClaimAsMap("realm_access")
            val roles = realmAccess?.get("roles") as? List<String> ?: emptyList()
            
            // Log para debug (solo en desarrollo)
            if (roles.isNotEmpty()) {
                println("🔐 SecurityConfig: Roles extraídos del JWT: $roles")
            } else {
                println("⚠️ SecurityConfig: No se encontraron roles en el JWT")
                println("📋 Realm access: $realmAccess")
            }
            
            roles.map { role ->
                // Mapear roles de Keycloak (minúsculas) a roles de Spring Security (ROLE_MAYÚSCULAS)
                when (role.lowercase()) {
                    "sudo" -> SimpleGrantedAuthority("ROLE_SUDO")
                    "admin" -> SimpleGrantedAuthority("ROLE_ADMIN")
                    "almacenista" -> SimpleGrantedAuthority("ROLE_ALMACENISTA")
                    "ventas" -> SimpleGrantedAuthority("ROLE_VENTAS")
                    "user" -> SimpleGrantedAuthority("ROLE_USER")
                    else -> SimpleGrantedAuthority("ROLE_${role.uppercase()}")
                }
            }
        }
        return ReactiveJwtAuthenticationConverterAdapter(converter)
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val configuration = CorsConfiguration()
        configuration.allowedOriginPatterns = listOf("*")
        configuration.allowedMethods = listOf("GET", "POST", "PUT", "DELETE", "OPTIONS")
        configuration.allowedHeaders = listOf("*")
        configuration.allowCredentials = true
        configuration.exposedHeaders = listOf("Authorization")

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", configuration)
        return source
    }
}
