package com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.AuditLog
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

interface AuditLogRepository {
    fun findAll(page: Int, size: Int): Flux<AuditLog>
    fun findById(id: Long): Mono<AuditLog>
    fun save(auditLog: AuditLog): Mono<AuditLog>
    fun deleteById(id: Long): Mono<Void>
    fun findByUserId(userId: Long): Flux<AuditLog>
    fun findByAction(action: String): Flux<AuditLog>
    fun findByCreatedAtBetween(start: LocalDateTime, end: LocalDateTime): Flux<AuditLog>
    fun deleteByUserId(userId: Long): Mono<Void>
}