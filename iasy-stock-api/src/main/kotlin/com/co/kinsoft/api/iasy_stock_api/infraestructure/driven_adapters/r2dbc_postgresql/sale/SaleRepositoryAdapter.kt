package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.sale

import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.gateway.SaleRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.math.BigDecimal
import java.time.LocalDate

@Repository
class SaleRepositoryAdapter(
    private val saleDAORepository: SaleDAORepository,
    private val saleMapper: SaleMapper
) : SaleRepository {

    override fun findAll(page: Int, size: Int): Flux<Sale> {
        val comparator = compareByDescending<SaleDAO> {
            it.saleDate ?: it.createdAt
        }.thenByDescending { it.id }

        return saleDAORepository.findAll()
            .sort(comparator)
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Sale> {
        return saleDAORepository.findById(id)
            .map { saleMapper.toDomain(it) }
    }

    override fun save(sale: Sale): Mono<Sale> {
        val saleDAO = saleMapper.toDAO(sale)
        return saleDAORepository.save(saleDAO)
            .map { saleMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return saleDAORepository.deleteById(id)
    }

    override fun findByUserId(userId: Long, page: Int, size: Int): Flux<Sale> {
        return saleDAORepository.findByUserId(userId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleMapper.toDomain(it) }
    }

    override fun findByPersonId(personId: Long, page: Int, size: Int): Flux<Sale> {
        return saleDAORepository.findByPersonId(personId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleMapper.toDomain(it) }
    }

    override fun findBySaleDate(saleDate: LocalDate, page: Int, size: Int): Flux<Sale> {
        return saleDAORepository.findBySaleDate(saleDate)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleMapper.toDomain(it) }
    }

    override fun findByTotalAmountGreaterThan(amount: BigDecimal, page: Int, size: Int): Flux<Sale> {
        return saleDAORepository.findByTotalAmountGreaterThan(amount)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleMapper.toDomain(it) }
    }

    override fun findByState(state: String, page: Int, size: Int): Flux<Sale> {
        return saleDAORepository.findByState(state)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleMapper.toDomain(it) }
    }
}
