package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.auditlog

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

interface AuditLogDAORepository : ReactiveCrudRepository<AuditLogDAO, Long> {
    fun findByUserId(userId: Long): Flux<AuditLogDAO>
    fun findByAction(action: String): Flux<AuditLogDAO>
    fun findByCreatedAtBetween(start: LocalDateTime, end: LocalDateTime): Flux<AuditLogDAO>
    fun deleteByUserId(userId: Long): Mono<Void>
}