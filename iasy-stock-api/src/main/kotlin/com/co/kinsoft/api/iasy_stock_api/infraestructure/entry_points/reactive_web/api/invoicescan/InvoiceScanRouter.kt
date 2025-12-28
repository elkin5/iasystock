package com.co.kinsoft.api.iasy_stock_api.infraestructure.entry_points.reactive_web.api.invoicescan

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.server.RequestPredicates.path
import org.springframework.web.reactive.function.server.RouterFunction
import org.springframework.web.reactive.function.server.RouterFunctions
import org.springframework.web.reactive.function.server.ServerResponse

/**
 * Router para endpoints de escaneo de facturas con OCR
 *
 * Base path: /api/v1/invoice-scan
 *
 * Endpoints:
 * - POST /scan - Escanea factura y extrae productos
 * - GET /search-products - Busca productos por nombre
 * - POST /confirm - Confirma y registra productos
 */
@Configuration
class InvoiceScanRouter(
    private val handler: InvoiceScanHandler
) {

    @Bean
    fun invoiceScanRoutes(): RouterFunction<ServerResponse> = RouterFunctions.nest(
        path("/api/v1/invoice-scan"),
        RouterFunctions.route()
            // Endpoint principal de escaneo OCR
            .POST("/scan", handler::scanInvoice)

            // Endpoint de búsqueda de productos
            .GET("/search-products", handler::searchProducts)

            // Endpoint de confirmación y registro
            .POST("/confirm", handler::confirmAndRegister)

            .build()
    )
}
