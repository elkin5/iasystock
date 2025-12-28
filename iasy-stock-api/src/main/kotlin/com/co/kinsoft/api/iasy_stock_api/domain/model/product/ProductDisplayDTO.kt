package com.co.kinsoft.api.iasy_stock_api.domain.model.product

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

data class ProductDisplayDTO(
    val id: Long = 0,
    val name: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val categoryId: Long,
    val price: BigDecimal? = null,
    val stockQuantity: Int? = null,
    val stockMinimum: Int? = null,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val expirationDate: LocalDate? = null,
) {
    override fun toString(): String {
        return """
            {
                "id": $id,
                "name": "$name",
                "description": "${description ?: "Sin descripción"}",
                "imageUrl": "${imageUrl ?: "Sin URL de imagen"}",
                "categoryId": $categoryId,
                "price": ${price ?: "Sin precio"},
                "stockQuantity": ${stockQuantity ?: "Sin cantidad"},
                "stockMinimum": ${stockMinimum ?: "Sin mínimo"},
                "createdAt": "$createdAt",
                "expirationDate": "${expirationDate ?: "Sin fecha de vencimiento"}",
            }
        """.trimIndent()
    }
}

// Función de extensión para convertir Product a ProductDisplay
fun Product.toDisplay(): ProductDisplayDTO {
    return ProductDisplayDTO(
        id = this.id,
        name = this.name,
        description = this.description,
        imageUrl = this.imageUrl,
        categoryId = this.categoryId,
        stockQuantity = this.stockQuantity,
        stockMinimum = this.stockMinimum,
        createdAt = this.createdAt,
        expirationDate = this.expirationDate
    )
}