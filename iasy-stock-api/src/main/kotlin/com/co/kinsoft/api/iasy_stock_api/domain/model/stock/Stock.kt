package com.co.kinsoft.api.iasy_stock_api.domain.model.stock

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

data class Stock(
    val id: Long = 0,
    val quantity: Int,
    val entryPrice: BigDecimal,
    val salePrice: BigDecimal,
    val productId: Long,
    val userId: Long,
    val warehouseId: Long? = null,
    val personId: Long? = null,
    val entryDate: LocalDate? = null,
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    fun isValid(): Boolean = quantity != 0 && entryPrice > BigDecimal.ZERO && salePrice > BigDecimal.ZERO && productId > 0 && userId > 0
    
    fun isStockIn(): Boolean = quantity > 0

    fun isStockOut(): Boolean = quantity < 0

    fun profitMargin(): BigDecimal {
        return if (salePrice > entryPrice) salePrice - entryPrice else BigDecimal.ZERO
    }
    
    fun hasWarehouse(): Boolean = warehouseId != null && warehouseId > 0
    
    fun hasPerson(): Boolean = personId != null && personId > 0
    
    fun hasEntryDate(): Boolean = entryDate != null
    
    fun getDisplayWarehouse(): String = if (hasWarehouse()) "Almacén ID: $warehouseId" else "Sin almacén"
    
    fun getDisplayPerson(): String = if (hasPerson()) "Persona ID: $personId" else "Sin persona"
    
    fun getDisplayEntryDate(): String = entryDate?.toString() ?: "Sin fecha de entrada"
    
    fun getDisplayProfitMargin(): String = "Margen: ${profitMargin()}"

    override fun toString(): String {
        return """
            {
                "id": $id,
                "quantity": $quantity,
                "entryPrice": $entryPrice,
                "salePrice": $salePrice,
                "productId": $productId,
                "userId": $userId,
                "warehouseId": "${getDisplayWarehouse()}",
                "personId": "${getDisplayPerson()}",
                "entryDate": "${getDisplayEntryDate()}",
                "createdAt": "$createdAt",
                "profitMargin": "${getDisplayProfitMargin()}"
            }
        """.trimIndent()
    }
}