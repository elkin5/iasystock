package com.co.kinsoft.api.iasy_stock_api.domain.usecase.auditlog

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.AuditLog
import com.co.kinsoft.api.iasy_stock_api.domain.model.auditlog.gateway.AuditLogRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDateTime

class AuditLogUseCase(private val auditLogRepository: AuditLogRepository) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<AuditLog> =
        auditLogRepository.findAll(page, size)

    fun findById(id: Long): Mono<AuditLog> =
        auditLogRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("El log de auditoría con ID $id no existe.")))

    fun save(auditLog: AuditLog): Mono<AuditLog> =
        Mono.fromCallable {
            AuditLogValidator.validate(auditLog)
            auditLog
        }.flatMap { auditLogRepository.save(it) }

    fun deleteById(id: Long): Mono<Void> =
        auditLogRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: el log con ID $id no existe.")))
            .flatMap { auditLogRepository.deleteById(id) }

    fun findByUserId(userId: Long): Flux<AuditLog> {
        if (userId <= 0) {
            return Flux.error(InvalidDataException("El ID de usuario debe ser un valor positivo."))
        }
        return auditLogRepository.findByUserId(userId)
    }

    fun findByAction(action: String): Flux<AuditLog> {
        if (action.isBlank()) {
            return Flux.error(InvalidDataException("La acción no puede estar vacía."))
        }
        return auditLogRepository.findByAction(action)
    }

    fun findByCreatedAtBetween(start: LocalDateTime, end: LocalDateTime): Flux<AuditLog> {
        if (start.isAfter(end)) {
            return Flux.error(InvalidDataException("La fecha de inicio no puede ser posterior a la fecha de fin."))
        }
        return auditLogRepository.findByCreatedAtBetween(start, end)
    }

    fun deleteByUserId(userId: Long): Mono<Void> {
        if (userId <= 0) {
            return Mono.error(InvalidDataException("El ID de usuario debe ser un valor positivo."))
        }
        return auditLogRepository.deleteByUserId(userId)
    }
}