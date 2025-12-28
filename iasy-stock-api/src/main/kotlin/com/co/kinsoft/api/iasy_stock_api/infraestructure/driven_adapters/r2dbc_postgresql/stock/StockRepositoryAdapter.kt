package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.stock

import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock
import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.gateway.StockRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono
import java.time.LocalDate

@Repository
class StockRepositoryAdapter(
    private val stockDAORepository: StockDAORepository,
    private val stockMapper: StockMapper
) : StockRepository {

    override fun findAll(page: Int, size: Int): Flux<Stock> {
        return stockDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Stock> {
        return stockDAORepository.findById(id)
            .map { stockMapper.toDomain(it) }
    }

    override fun save(stock: Stock): Mono<Stock> {
        val stockDAO = stockMapper.toDAO(stock)
        return stockDAORepository.save(stockDAO)
            .map { stockMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return stockDAORepository.deleteById(id)
    }

    override fun findByProductId(productId: Long, page: Int, size: Int): Flux<Stock> {
        return stockDAORepository.findByProductId(productId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }

    override fun findByWarehouseId(warehouseId: Long, page: Int, size: Int): Flux<Stock> {
        return stockDAORepository.findByWarehouseId(warehouseId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }

    override fun findByUserId(userId: Long, page: Int, size: Int): Flux<Stock> {
        return stockDAORepository.findByUserId(userId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }

    override fun findByEntryDate(entryDate: LocalDate, page: Int, size: Int): Flux<Stock> {
        return stockDAORepository.findByEntryDate(entryDate)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }

    override fun findByQuantityGreaterThan(quantity: Int, page: Int, size: Int): Flux<Stock> {
        return stockDAORepository.findByQuantityGreaterThan(quantity)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }

    override fun findByPersonId(personId: Long, page: Int, size: Int
    ): Flux<Stock> {
        return stockDAORepository.findByPersonId(personId)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { stockMapper.toDomain(it) }
    }
}