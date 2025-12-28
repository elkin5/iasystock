package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.auditlog

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.time.LocalDateTime

@Table("AuditLog", schema = "schmain")
data class AuditLogDAO(
    @Id
    @Column("log_id")
    var id: Long = 0,

    @Column("user_id")
    var userId: Long,

    @Column("action")
    var action: String,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column("description")
    var description: String? = null
)