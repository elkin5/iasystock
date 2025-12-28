package com.co.kinsoft.api.iasy_stock_api.domain.model.stats

import java.math.BigDecimal

data class TopProductStat(
    val productId: Long,
    val productName: String,
    val totalQuantity: Long,
    val totalAmount: BigDecimal
)

