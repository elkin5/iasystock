package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.productidentification

import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.CorrectionType
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.IdentificationThresholdConfig
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ProductIdentificationValidation
import com.co.kinsoft.api.iasy_stock_api.domain.model.productidentification.ValidationSource

/**
 * Mappers para convertir entre DAOs y modelos de dominio
 * de Product Identification
 */
object ProductIdentificationMappers {

    /**
     * Convierte ProductIdentificationValidationDAO a ProductIdentificationValidation
     */
    fun ProductIdentificationValidationDAO.toDomain(): ProductIdentificationValidation {
        return ProductIdentificationValidation(
            validationId = this.validationId,
            imageHash = this.imageHash,
            imageUrl = this.imageUrl,
            imageEmbedding = this.imageEmbedding,
            suggestedProductId = this.suggestedProductId,
            actualProductId = this.actualProductId,
            confidenceScore = this.confidenceScore,
            matchType = this.matchType,
            similarityScore = this.similarityScore,
            wasCorrect = this.wasCorrect,
            correctionType = CorrectionType.valueOf(this.correctionType),
            validatedBy = this.validatedBy,
            validatedAt = this.validatedAt,
            feedbackNotes = this.feedbackNotes,
            validationSource = ValidationSource.valueOf(this.validationSource),
            relatedSaleId = this.relatedSaleId,
            relatedStockId = this.relatedStockId,
            metadata = this.metadata,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * Convierte ProductIdentificationValidation a ProductIdentificationValidationDAO
     */
    fun ProductIdentificationValidation.toDAO(): ProductIdentificationValidationDAO {
        return ProductIdentificationValidationDAO(
            validationId = this.validationId,
            imageHash = this.imageHash,
            imageUrl = this.imageUrl,
            imageEmbedding = this.imageEmbedding,
            suggestedProductId = this.suggestedProductId,
            actualProductId = this.actualProductId,
            confidenceScore = this.confidenceScore,
            matchType = this.matchType,
            similarityScore = this.similarityScore,
            wasCorrect = this.wasCorrect,
            correctionType = this.correctionType.name,
            validatedBy = this.validatedBy,
            validatedAt = this.validatedAt,
            feedbackNotes = this.feedbackNotes,
            validationSource = this.validationSource.name,
            relatedSaleId = this.relatedSaleId,
            relatedStockId = this.relatedStockId,
            metadata = this.metadata,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * Convierte ProductIdentificationThresholdConfigDAO a IdentificationThresholdConfig
     */
    fun ProductIdentificationThresholdConfigDAO.toDomain(): IdentificationThresholdConfig {
        return IdentificationThresholdConfig(
            configId = this.configId,
            barcodeMinConfidence = this.barcodeMinConfidence,
            hashMinConfidence = this.hashMinConfidence,
            brandModelMinConfidence = this.brandModelMinConfidence,
            vectorSimilarityMinConfidence = this.vectorSimilarityMinConfidence,
            tagCategoryMinConfidence = this.tagCategoryMinConfidence,
            autoApproveThreshold = this.autoApproveThreshold,
            manualValidationThreshold = this.manualValidationThreshold,
            totalIdentifications = this.totalIdentifications,
            correctIdentifications = this.correctIdentifications,
            falsePositives = this.falsePositives,
            falseNegatives = this.falseNegatives,
            accuracy = this.accuracy,
            lastTrainingAt = this.lastTrainingAt,
            trainingSamplesCount = this.trainingSamplesCount,
            modelVersion = this.modelVersion,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * Convierte IdentificationThresholdConfig a ProductIdentificationThresholdConfigDAO
     */
    fun IdentificationThresholdConfig.toDAO(): ProductIdentificationThresholdConfigDAO {
        return ProductIdentificationThresholdConfigDAO(
            configId = this.configId,
            barcodeMinConfidence = this.barcodeMinConfidence,
            hashMinConfidence = this.hashMinConfidence,
            brandModelMinConfidence = this.brandModelMinConfidence,
            vectorSimilarityMinConfidence = this.vectorSimilarityMinConfidence,
            tagCategoryMinConfidence = this.tagCategoryMinConfidence,
            autoApproveThreshold = this.autoApproveThreshold,
            manualValidationThreshold = this.manualValidationThreshold,
            totalIdentifications = this.totalIdentifications,
            correctIdentifications = this.correctIdentifications,
            falsePositives = this.falsePositives,
            falseNegatives = this.falseNegatives,
            accuracy = this.accuracy,
            lastTrainingAt = this.lastTrainingAt,
            trainingSamplesCount = this.trainingSamplesCount,
            modelVersion = this.modelVersion,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }
}

/**
 * Extension functions para conversión más fluida
 */

// Validation
fun ProductIdentificationValidationDAO.toDomain() =
    ProductIdentificationMappers.run { this@toDomain.toDomain() }

fun ProductIdentificationValidation.toDAO() =
    ProductIdentificationMappers.run { this@toDAO.toDAO() }

// ThresholdConfig
fun ProductIdentificationThresholdConfigDAO.toDomain() =
    ProductIdentificationMappers.run { this@toDomain.toDomain() }

fun IdentificationThresholdConfig.toDAO() =
    ProductIdentificationMappers.run { this@toDAO.toDAO() }
