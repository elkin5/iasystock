package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.auditlog

import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.AuditLog
import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.gateway.AuditLogRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

@Repository
class AuditLogRepositoryAdapter(
    private val auditLogDAORepository: AuditLogDAORepository,
    private val auditLogMapper: AuditLogMapper
) : AuditLogRepository {

    override fun findAll(page: Int, size: Int): Flux<AuditLog> {
        return auditLogDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { auditLogMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<AuditLog> {
        return auditLogDAORepository.findById(id)
            .map { auditLogMapper.toDomain(it) }
    }

    override fun save(auditLog: AuditLog): Mono<AuditLog> {
        val auditLogDAO = auditLogMapper.toDAO(auditLog)
        return auditLogDAORepository.save(auditLogDAO)
            .map { auditLogMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return auditLogDAORepository.deleteById(id)
    }

    override fun findByUserId(userId: Long): Flux<AuditLog> {
        return auditLogDAORepository.findByUserId(userId)
            .map { auditLogMapper.toDomain(it) }
    }

    override fun findByAction(action: String): Flux<AuditLog> {
        return auditLogDAORepository.findByAction(action)
            .map { auditLogMapper.toDomain(it) }
    }

    override fun findByCreatedAtBetween(start: LocalDateTime, end: LocalDateTime): Flux<AuditLog> {
        return auditLogDAORepository.findByCreatedAtBetween(start, end)
            .map { auditLogMapper.toDomain(it) }
    }

    override fun deleteByUserId(userId: Long): Mono<Void> {
        return auditLogDAORepository.deleteByUserId(userId)
    }
}