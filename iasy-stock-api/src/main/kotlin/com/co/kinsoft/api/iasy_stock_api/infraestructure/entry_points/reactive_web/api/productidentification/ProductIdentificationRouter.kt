package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.productidentification

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.path
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

/**
 * Router para endpoints de identificación inteligente de productos
 *
 * Base path: /api/v1/product-identification
 *
 * Endpoints:
 * - POST /identify-or-create - Identifica o crea producto desde imagen
 * - POST /identify-multiple - Detecta múltiples productos con GPT-4 Vision
 * - POST /validate - Registra validación humana
 * - GET /validations/recent - Obtiene validaciones recientes
 * - GET /config/active - Obtiene configuración activa
 * - GET /config/all - Obtiene todas las configuraciones
 * - GET /metrics - Obtiene métricas de precisión
 * - POST /retrain - Trigger manual de reentrenamiento
 */
@Configuration
class ProductIdentificationRouter(
    private val handler: ProductIdentificationHandler
) {

    @Bean
    fun productIdentificationRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(
        path("/api/v1/product-identification"),
        RouterFunctions.route()
            // Endpoint principal de identificación/creación
            .POST("/identify-or-create", handler::identifyOrCreate)

            // Endpoint de detección múltiple con GPT-4 Vision
            .POST("/identify-multiple", handler::identifyMultiple)

            // Endpoints de validación
            .POST("/validate", handler::validateIdentification)
            .GET("/validations/recent", handler::getRecentValidations)

            // Endpoints de configuración
            .GET("/config/active", handler::getActiveConfig)

            // Endpoints de métricas y ML
            .GET("/metrics", handler::getMetrics)
            .POST("/retrain", handler::triggerRetraining)

            .build()
    )
}
