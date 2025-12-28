package com.co.kinsoft.api.iasy_stock_api.config

import com.co.kinsoft.api.iasy_stock_api.domain.model.filestorage.FileStorageService
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ThresholdConfigRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.gateway.ValidationRepository
import com.co.kinsoft.api.iasy_stock_api.domain.model.productrecognition.ProductRecognitionService
import com.co.kinsoft.api.iasy_stock_api.domain.service.ProductIdentificationService
import com.co.kinsoft.api.iasy_stock_api.domain.service.ProductMLService
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.ValidationUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.product.ProductUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.promotion.PromotionUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.saleitem.SaleItemUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock.StockUseCase
import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.OpenAIService
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

/**
 * Configuración de beans para el sistema de identificación inteligente de productos
 *
 * Configura:
 * - ValidationUseCase - Caso de uso para validaciones humanas
 * - ProductUseCase - Caso de uso actualizado con identificación inteligente
 * - Otros beans relacionados ya están configurados con anotaciones @Service/@Repository
 */
@Configuration
class ProductIdentificationConfig {

    /**
     * Bean de ValidationUseCase
     *
     * Gestiona validaciones humanas de identificaciones y triggerea reentrenamiento automático
     */
    @Bean
    fun validationUseCase(
        validationRepository: ValidationRepository,
        thresholdConfigRepository: ThresholdConfigRepository,
        productMLService: ProductMLService
    ): ValidationUseCase {
        return ValidationUseCase(
            validationRepository = validationRepository,
            thresholdConfigRepository = thresholdConfigRepository,
            productMLService = productMLService
        )
    }

    /**
     * Bean de ProductUseCase
     *
     * Actualizado con sistema de identificación inteligente y detección múltiple con GPT-4 Vision
     */
    @Bean
    fun productUseCase(
        productRepository: ProductRepository,
        stockUseCase: StockUseCase,
        promotionUseCase: PromotionUseCase,
        saleItemUseCase: SaleItemUseCase,
        productRecognitionService: ProductRecognitionService,
        fileStorageService: FileStorageService,
        productIdentificationService: ProductIdentificationService,
        thresholdConfigRepository: ThresholdConfigRepository,
        openAIService: OpenAIService
    ): ProductUseCase {
        return ProductUseCase(
            productRepository = productRepository,
            stockUseCase = stockUseCase,
            promotionUseCase = promotionUseCase,
            saleItemUseCase = saleItemUseCase,
            productRecognitionService = productRecognitionService,
            fileStorageService = fileStorageService,
            productIdentificationService = productIdentificationService,
            thresholdConfigRepository = thresholdConfigRepository,
            openAIService = openAIService
        )
    }

    /**
     * Nota: Los siguientes beans ya están configurados automáticamente con anotaciones:
     *
     * @Service beans:
     * - ProductMLService
     * - ProductIdentificationService
     *
     * @Repository beans:
     * - ValidationRepositoryAdapter (implementa ValidationRepository)
     * - ThresholdConfigRepositoryAdapter (implementa ThresholdConfigRepository)
     * - ProductIdentificationValidationDAORepository (Spring Data R2DBC)
     * - ProductIdentificationThresholdConfigDAORepository (Spring Data R2DBC)
     *
     * @Component beans:
     * - ProductIdentificationHandler
     *
     * @Configuration beans:
     * - ProductIdentificationRouter
     */
}
