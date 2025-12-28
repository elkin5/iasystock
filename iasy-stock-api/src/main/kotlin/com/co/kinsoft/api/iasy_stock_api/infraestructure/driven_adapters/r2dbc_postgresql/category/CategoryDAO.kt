package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.category

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table

@Table("Category", schema = "schmain")
data class CategoryDAO(
    @Id
    @Column("category_id")
    var id: Long = 0,

    @Column("name")
    var name: String = "",

    @Column("description")
    var description: String? = null
)