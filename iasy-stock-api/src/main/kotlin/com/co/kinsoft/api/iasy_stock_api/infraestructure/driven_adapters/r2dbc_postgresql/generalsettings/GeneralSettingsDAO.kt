package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.generalsettings

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table

@Table("GeneralSettings", schema = "schmain")
data class GeneralSettingsDAO(
    @Id
    @Column("config_id")
    var id: Long = 0,

    @Column("key")
    var key: String,

    @Column("value")
    var value: String,

    @Column("description")
    var description: String? = null
)