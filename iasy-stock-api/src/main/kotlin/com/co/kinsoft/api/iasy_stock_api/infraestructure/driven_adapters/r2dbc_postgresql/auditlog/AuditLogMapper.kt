package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.auditlog

import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.AuditLog
import org.mapstruct.Mapper

@Mapper(componentModel = "spring")
interface AuditLogMapper {
    fun toDomain(auditLogDAO: AuditLogDAO): AuditLog
    fun toDAO(auditLog: AuditLog): AuditLogDAO
}