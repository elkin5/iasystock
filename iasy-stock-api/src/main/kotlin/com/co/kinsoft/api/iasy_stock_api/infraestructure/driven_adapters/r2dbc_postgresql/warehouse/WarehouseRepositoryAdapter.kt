package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.warehouse

import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.Warehouse
import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.gateway.WarehouseRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Repository
class WarehouseRepositoryAdapter(
    private val warehouseDAORepository: WarehouseDAORepository,
    private val warehouseMapper: WarehouseMapper
) : WarehouseRepository {

    override fun findAll(page: Int, size: Int): Flux<Warehouse> {
        return warehouseDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { warehouseMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Warehouse> {
        return warehouseDAORepository.findById(id)
            .map { warehouseMapper.toDomain(it) }
    }

    override fun save(warehouse: Warehouse): Mono<Warehouse> {
        val warehouseDAO = warehouseMapper.toDAO(warehouse)
        return warehouseDAORepository.save(warehouseDAO)
            .map { warehouseMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return warehouseDAORepository.deleteById(id)
    }

    override fun findByName(name: String, page: Int, size: Int): Flux<Warehouse> {
        return warehouseDAORepository.findByName(name)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { warehouseMapper.toDomain(it) }
    }

    override fun findByNameContaining(name: String, page: Int, size: Int): Flux<Warehouse> {
        return warehouseDAORepository.findByNameContaining(name)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { warehouseMapper.toDomain(it) }
    }

    override fun findByLocation(location: String, page: Int, size: Int): Flux<Warehouse> {
        return warehouseDAORepository.findByLocation(location)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { warehouseMapper.toDomain(it) }
    }
}