package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.person

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.time.LocalDateTime

@Table("Person", schema = "schmain")
data class PersonDAO(
    @Id
    @Column("person_id")
    var id: Long = 0,

    @Column("name")
    var name: String = "",

    @Column("identification")
    var identification: Long? = null,

    @Column("identification_type")
    var identificationType: String? = null,

    @Column("cell_phone")
    var cellPhone: Long? = null,

    @Column("email")
    var email: String? = null,

    @Column("address")
    var address: String? = null,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column("type")
    var type: String = ""
)