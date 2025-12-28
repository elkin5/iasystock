package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.promotion

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal
import java.time.LocalDate

@Table("Promotion", schema = "schmain")
data class PromotionDAO(
    @Id
    @Column("promo_id")
    var id: Long = 0,

    @Column("description")
    var description: String,

    @Column("discount_rate")
    var discountRate: BigDecimal,

    @Column("start_date")
    var startDate: LocalDate,

    @Column("end_date")
    var endDate: LocalDate,

    @Column("product_id")
    var productId: Long? = null,

    @Column("category_id")
    var categoryId: Long? = null
)