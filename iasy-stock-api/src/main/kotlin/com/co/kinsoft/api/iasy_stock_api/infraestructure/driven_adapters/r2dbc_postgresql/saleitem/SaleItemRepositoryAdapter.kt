package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.saleitem

import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.gateway.SaleItemRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Repository
class SaleItemRepositoryAdapter(
    private val saleItemDAORepository: SaleItemDAORepository,
    private val saleItemMapper: SaleItemMapper
) : SaleItemRepository {

    override fun findAll(page: Int, size: Int): Flux<SaleItem> {
        return saleItemDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleItemMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<SaleItem> {
        return saleItemDAORepository.findById(id)
            .map { saleItemMapper.toDomain(it) }
    }

    override fun save(saleItem: SaleItem): Mono<SaleItem> {
        val saleItemDAO = saleItemMapper.toDAO(saleItem)
        return saleItemDAORepository.save(saleItemDAO)
            .map { saleItemMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return saleItemDAORepository.deleteById(id)
    }

    override fun findBySaleId(saleId: Long, page: Int, size: Int): Flux<SaleItem> {
        return saleItemDAORepository.findBySaleId(saleId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleItemMapper.toDomain(it) }
    }

    override fun findByProductId(productId: Long, page: Int, size: Int): Flux<SaleItem> {
        return saleItemDAORepository.findByProductId(productId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { saleItemMapper.toDomain(it) }
    }
}