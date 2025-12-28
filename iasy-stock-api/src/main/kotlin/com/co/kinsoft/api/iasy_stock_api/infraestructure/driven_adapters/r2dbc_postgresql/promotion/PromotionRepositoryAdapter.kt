package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.promotion

import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.Promotion
import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.gateway.PromotionRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

@Repository
class PromotionRepositoryAdapter(
    private val promotionDAORepository: PromotionDAORepository,
    private val promotionMapper: PromotionMapper
) : PromotionRepository {

    override fun findAll(page: Int, size: Int): Flux<Promotion> {
        return promotionDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { promotionMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Promotion> {
        return promotionDAORepository.findById(id)
            .map { promotionMapper.toDomain(it) }
    }

    override fun save(promotion: Promotion): Mono<Promotion> {
        val promotionDAO = promotionMapper.toDAO(promotion)
        return promotionDAORepository.save(promotionDAO)
            .map { promotionMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return promotionDAORepository.deleteById(id)
    }

    override fun findByDescription(description: String, page: Int, size: Int): Flux<Promotion> {
        return promotionDAORepository.findByDescriptionContainingIgnoreCase(description)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { promotionMapper.toDomain(it) }
    }

    override fun findByDiscountRateGreaterThan(rate: BigDecimal, page: Int, size: Int): Flux<Promotion> {
        return promotionDAORepository.findByDiscountRateGreaterThan(rate)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { promotionMapper.toDomain(it) }
    }

    override fun findByStartDateBeforeAndEndDateAfter(
        startDate: LocalDate, endDate: LocalDate, page: Int, size: Int
    ): Flux<Promotion> {
        return promotionDAORepository.findByStartDateBeforeAndEndDateAfter(startDate, endDate)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { promotionMapper.toDomain(it) }
    }

    override fun findByProductId(productId: Long?, page: Int, size: Int): Flux<Promotion> {
        return promotionDAORepository.findByProductId(productId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { promotionMapper.toDomain(it) }
    }

    override fun findByCategoryId(categoryId: Long, page: Int, size: Int): Flux<Promotion> {
        return promotionDAORepository.findByCategoryId(categoryId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { promotionMapper.toDomain(it) }
    }
}