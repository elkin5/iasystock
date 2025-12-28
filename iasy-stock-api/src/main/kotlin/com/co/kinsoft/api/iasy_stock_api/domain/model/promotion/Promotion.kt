package com.co.kinsoft.api.iasy_stock_api.domain.model.promotion

import java.math.BigDecimal
import java.time.LocalDate

data class Promotion(
    val id: Long = 0,
    val description: String,
    val discountRate: BigDecimal,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val productId: Long? = null,
    val categoryId: Long? = null
) {
    fun isValid(): Boolean = description.isNotBlank() && 
        discountRate > BigDecimal.ZERO && 
        discountRate <= BigDecimal(100) &&
        !endDate.isBefore(startDate) &&
        (productId == null || productId > 0) &&
        (categoryId == null || categoryId > 0)
    
    fun isActive(currentDate: LocalDate = LocalDate.now()): Boolean {
        return !currentDate.isBefore(startDate) && !currentDate.isAfter(endDate)
    }
    
    fun isExpired(currentDate: LocalDate = LocalDate.now()): Boolean {
        return currentDate.isAfter(endDate)
    }
    
    fun isFuture(currentDate: LocalDate = LocalDate.now()): Boolean {
        return currentDate.isBefore(startDate)
    }
    
    fun hasValidDates(): Boolean = !endDate.isBefore(startDate)
    
    fun hasValidDiscountRate(): Boolean = discountRate > BigDecimal.ZERO && discountRate <= BigDecimal(100)
    
    fun hasProduct(): Boolean = productId != null && productId > 0
    fun hasCategory(): Boolean = categoryId != null && categoryId > 0
    
    fun getDisplayDescription(): String = description.takeIf { it.isNotBlank() } ?: "Sin descripción"
    fun getDisplayDiscountRate(): String = "Descuento: ${discountRate}%"
    fun getDisplayDateRange(): String = "Del $startDate al $endDate"
    fun getDisplayProduct(): String = if (hasProduct()) "Producto ID: $productId" else "Sin producto específico"
    fun getDisplayCategory(): String = if (hasCategory()) "Categoría ID: $categoryId" else "Sin categoría específica"
    fun getDisplayStatus(): String = when {
        isActive() -> "Activa"
        isExpired() -> "Expirada"
        isFuture() -> "Futura"
        else -> "Desconocida"
    }

    override fun toString(): String {
        return """
            {
                "id": $id,
                "description": "$description",
                "discountRate": $discountRate,
                "startDate": "$startDate",
                "endDate": "$endDate",
                "productId": ${productId ?: "Sin producto asociado"},
                "categoryId": ${categoryId ?: "Sin categoría asociada"},
                "isActive": ${isActive()},
                "isValid": ${isValid()}
            }
        """.trimIndent()
    }
}