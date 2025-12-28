package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.stock

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

@Table("Stock", schema = "schmain")
data class StockDAO(
    @Id
    @Column("stock_id")
    var id: Long = 0,

    @Column("quantity")
    var quantity: Int,

    @Column("entry_price")
    var entryPrice: BigDecimal,

    @Column("sale_price")
    var salePrice: BigDecimal,

    @Column("product_id")
    var productId: Long,

    @Column("user_id")
    var userId: Long,

    @Column("warehouse_id")
    var warehouseId: Long? = null,

    @Column("person_id")
    var personId: Long? = null,

    @Column("entry_date")
    var entryDate: LocalDate? = null,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now()
)