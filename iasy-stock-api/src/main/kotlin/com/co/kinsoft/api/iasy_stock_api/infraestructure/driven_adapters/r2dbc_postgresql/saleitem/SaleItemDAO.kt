package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.saleitem

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.math.BigDecimal

@Table("SaleItem", schema = "schmain")
data class SaleItemDAO(
    @Id
    @Column("sale_item_id")
    var id: Long = 0,

    @Column("sale_id")
    var saleId: Long,

    @Column("product_id")
    var productId: Long,

    @Column("quantity")
    var quantity: Int,

    @Column("unit_price")
    var unitPrice: BigDecimal,

    @Column("total_price")
    var totalPrice: BigDecimal
)