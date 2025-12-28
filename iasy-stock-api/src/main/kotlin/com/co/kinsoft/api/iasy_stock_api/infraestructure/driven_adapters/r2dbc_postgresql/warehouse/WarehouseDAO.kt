package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.warehouse

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.time.LocalDateTime

@Table("Warehouse", schema = "schmain")
data class WarehouseDAO(
    @Id
    @Column("warehouse_id")
    var id: Long = 0,

    @Column("name")
    var name: String = "",

    @Column("location")
    var location: String? = null,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now()
)