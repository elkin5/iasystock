package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.user

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.relational.core.mapping.Table
import java.time.LocalDateTime

@Table("User", schema = "schmain")
data class UserDAO(
    @Id
    @Column("id")
    var id: Long = 0,

    @Column("keycloak_id")
    var keycloakId: String? = null,

    @Column("username")
    var username: String,

    @Column("password")
    var password: String? = null,

    @Column("email")
    var email: String? = null,

    @Column("first_name")
    var firstName: String? = null,

    @Column("last_name")
    var lastName: String? = null,

    @Column("role")
    var role: String,

    @Column("is_active")
    var isActive: Boolean = true,

    @Column("last_login_at")
    var lastLoginAt: LocalDateTime? = null,

    @Column("created_at")
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column("updated_at")
    var updatedAt: LocalDateTime = LocalDateTime.now()
)