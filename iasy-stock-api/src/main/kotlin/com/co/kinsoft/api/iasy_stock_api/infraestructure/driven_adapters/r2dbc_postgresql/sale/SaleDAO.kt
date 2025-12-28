package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.sale

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

@Table("Sale", schema = "schmain")
data class SaleDAO(
    @Id
    @Column("sale_id")
    var id: Long = 0,

    @Column("person_id")
    var personId: Long? = null,

    @Column("user_id")
    var userId: Long,

    @Column("total_amount")
    var totalAmount: BigDecimal,

    @Column("sale_date")
    var saleDate: LocalDateTime? = null,

    @Column("pay_method")
    var payMethod: String? = null,

    @Column("state")
    var state: String? = null,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now()
)