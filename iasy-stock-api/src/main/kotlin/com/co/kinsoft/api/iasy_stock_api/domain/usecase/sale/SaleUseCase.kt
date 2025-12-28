package com.co.kinsoft.api.iasy_stock_api.domain.usecase.sale

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.gateway.SaleRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

class SaleUseCase(private val saleRepository: SaleRepository) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Sale> =
        saleRepository.findAll(page, size)

    fun findById(id: Long): Mono<Sale> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return saleRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La venta con ID $id no existe.")))
    }

    fun create(sale: Sale): Mono<Sale> {
        return Mono.fromCallable {
            SaleValidator.validate(sale)
            sale.copy(createdAt = LocalDateTime.now())
        }.flatMap { saleRepository.save(it) }
    }

    fun update(id: Long, sale: Sale): Mono<Sale> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            SaleValidator.validate(sale)
            sale
        }.flatMap {
            saleRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("La venta con ID $id no existe.")))
        }.flatMap { existingSale ->
            val updatedSale = existingSale.copy(
                personId = sale.personId,
                userId = sale.userId,
                totalAmount = sale.totalAmount,
                saleDate = sale.saleDate,
                payMethod = sale.payMethod,
                state = sale.state
            )
            saleRepository.save(updatedSale)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return saleRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: la venta con ID $id no existe.")))
            .flatMap { saleRepository.deleteById(id) }
    }

    fun findByUserId(userId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Sale> {
        if (userId <= 0) {
            return Flux.error(InvalidDataException("El ID del usuario debe ser un valor positivo."))
        }
        return saleRepository.findByUserId(userId, page, size)
    }

    fun findByPersonId(personId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Sale> {
        if (personId <= 0) {
            return Flux.error(InvalidDataException("El ID de la persona debe ser un valor positivo."))
        }
        return saleRepository.findByPersonId(personId, page, size)
    }

    fun findBySaleDate(saleDate: LocalDate, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Sale> {
        return saleRepository.findBySaleDate(saleDate, page, size)
    }

    fun findByTotalAmountGreaterThan(
        amount: BigDecimal,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Sale> {
        if (amount < BigDecimal.ZERO) {
            return Flux.error(InvalidDataException("El monto mínimo debe ser cero o mayor."))
        }
        return saleRepository.findByTotalAmountGreaterThan(amount, page, size)
    }

    fun findByState(state: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Sale> {
        if (state.isBlank()) {
            return Flux.error(InvalidDataException("El estado no puede estar en blanco."))
        }
        return saleRepository.findByState(state, page, size)
    }
}