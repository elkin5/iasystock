package com.co.kinsoft.api.iasy_stock_api.domain.model.stats

import java.math.BigDecimal
import java.time.LocalDate

data class SalesByDateStat(
    val date: LocalDate,
    val totalSales: Long,
    val totalAmount: BigDecimal
)

