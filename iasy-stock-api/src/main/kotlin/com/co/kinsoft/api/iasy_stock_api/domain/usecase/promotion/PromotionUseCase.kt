package com.co.kinsoft.api.iasy_stock_api.domain.usecase.promotion

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.DomainException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.Promotion
import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.gateway.PromotionRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

class PromotionUseCase(private val promotionRepository: PromotionRepository) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Promotion> =
        promotionRepository.findAll(page, size)

    fun findById(id: Long): Mono<Promotion> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID de la promoción debe ser un valor positivo."))
        }
        return promotionRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La promoción con ID $id no existe.")))
    }

    fun create(promotion: Promotion): Mono<Promotion> {
        return Mono.fromCallable {
            PromotionValidator.validate(promotion)
            promotion
        }.flatMap {
            promotionRepository.findByProductId(promotion.productId, DEFAULT_PAGE, DEFAULT_SIZE)
                .filter { existing ->
                    !(promotion.endDate.isBefore(existing.startDate) || promotion.startDate.isAfter(existing.endDate))
                }
                .hasElements()
                .flatMap { conflict ->
                    if (conflict) {
                        Mono.error(DomainException("Ya existe una promoción activa para este producto en el rango de fechas indicado."))
                    } else {
                        promotionRepository.save(promotion)
                    }
                }
        }
    }

    fun update(id: Long, promotion: Promotion): Mono<Promotion> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID de la promoción debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            PromotionValidator.validate(promotion)
            promotion
        }.flatMap {
            promotionRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("La promoción con ID $id no existe.")))
        }.flatMap { existingPromotion ->
            val updatedPromotion = existingPromotion.copy(
                description = promotion.description,
                discountRate = promotion.discountRate,
                startDate = promotion.startDate,
                endDate = promotion.endDate,
                productId = promotion.productId,
                categoryId = promotion.categoryId
            )
            promotionRepository.save(updatedPromotion)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return promotionRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: la promoción con ID $id no existe.")))
            .flatMap { promotionRepository.deleteById(id) }
    }

    fun findByDescription(description: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Promotion> {
        if (description.isBlank()) {
            return Flux.error(InvalidDataException("La descripción no puede estar en blanco."))
        }
        return promotionRepository.findByDescription(description, page, size)
    }

    fun findByDiscountRateGreaterThan(rate: BigDecimal, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Promotion> {
        if (rate < BigDecimal.ZERO) {
            return Flux.error(InvalidDataException("La tasa de descuento no puede ser negativa."))
        }
        return promotionRepository.findByDiscountRateGreaterThan(rate, page, size)
    }

    fun findByStartDateBeforeAndEndDateAfter(
        startDate: LocalDate,
        endDate: LocalDate,
        page: Int = DEFAULT_PAGE,
        size: Int = DEFAULT_SIZE
    ): Flux<Promotion> {
        if (startDate.isAfter(endDate)) {
            return Flux.error(InvalidDataException("La fecha de inicio no puede ser posterior a la fecha de fin."))
        }
        return promotionRepository.findByStartDateBeforeAndEndDateAfter(startDate, endDate, page, size)
    }

    fun findByProductId(productId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Promotion> {
        if (productId <= 0) {
            return Flux.error(InvalidDataException("El ID del producto debe ser un valor positivo."))
        }
        return promotionRepository.findByProductId(productId, page, size)
    }

    fun findByCategoryId(categoryId: Long, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Promotion> {
        if (categoryId <= 0) {
            return Flux.error(InvalidDataException("El ID de la categoría debe ser un valor positivo."))
        }
        return promotionRepository.findByCategoryId(categoryId, page, size)
    }
}