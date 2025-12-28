package com.co.kinsoft.api.iasy_stock_api.domain.model.sale

import java.math.BigDecimal
import java.time.LocalDateTime

data class Sale(
    val id: Long = 0,
    val personId: Long? = null,
    val userId: Long,
    val totalAmount: BigDecimal,
    val saleDate: LocalDateTime? = null,
    val payMethod: String? = null,
    val state: String? = null,
    val createdAt: LocalDateTime? = null
) {
    fun isValid(): Boolean = userId > 0 && totalAmount > BigDecimal.ZERO

    fun isCompleted(): Boolean = state.equals("Completada", ignoreCase = true)
    fun isPending(): Boolean = state.equals("Pendiente", ignoreCase = true)
    fun isCancelled(): Boolean = state.equals("Cancelada", ignoreCase = true)

    fun hasPerson(): Boolean = personId != null && personId > 0
    fun hasSaleDate(): Boolean = saleDate != null
    fun hasPayMethod(): Boolean = !payMethod.isNullOrBlank()
    fun hasState(): Boolean = !state.isNullOrBlank()

    fun getDisplayPerson(): String = if (hasPerson()) "Cliente ID: $personId" else "Sin cliente"
    fun getDisplaySaleDate(): String = saleDate?.toString() ?: "Sin fecha de venta"
    fun getDisplayPayMethod(): String = payMethod?.takeIf { it.isNotBlank() } ?: "Sin método de pago"
    fun getDisplayState(): String = state?.takeIf { it.isNotBlank() } ?: "Sin estado"
    fun getDisplayTotalAmount(): String = "Total: $totalAmount"
    fun getDisplayCreatedAt(): String = createdAt?.toString() ?: "Sin fecha de creación"

    fun hasCreatedAt(): Boolean = createdAt != null

    override fun toString(): String {
        return """
            {
                "id": $id,
                "personId": "${getDisplayPerson()}",
                "userId": $userId,
                "totalAmount": "${getDisplayTotalAmount()}",
                "saleDate": "${getDisplaySaleDate()}",
                "payMethod": "${getDisplayPayMethod()}",
                "state": "${getDisplayState()}",
                "createdAt": "${getDisplayCreatedAt()}"
            }
        """.trimIndent()
    }
}