package com.co.kinsoft.api.iasy_stock_api.domain.usecase.warehouse

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.ReferentialIntegrityException
import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.Warehouse
import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.gateway.WarehouseRepository
import org.springframework.dao.DataIntegrityViolationException
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

class WarehouseUseCase(private val warehouseRepository: WarehouseRepository) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Warehouse> =
        warehouseRepository.findAll(page, size)

    fun findById(id: Long): Mono<Warehouse> {
        if (id <= 0) return Mono.error(InvalidDataException("El ID debe ser un número positivo."))
        return warehouseRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La bodega con ID $id no existe.")))
    }

    fun create(warehouse: Warehouse): Mono<Warehouse> {
        return Mono.fromCallable {
            WarehouseValidator.validate(warehouse)
            warehouse
        }.flatMap {
            warehouseRepository.findByName(warehouse.name, DEFAULT_PAGE, DEFAULT_SIZE)
                .hasElements()
                .flatMap { exists ->
                    if (exists) {
                        Mono.error(AlreadyExistsException("Ya existe una bodega con el nombre '${warehouse.name}'"))
                    } else {
                        warehouseRepository.save(warehouse)
                    }
                }
        }
    }

    fun update(id: Long, warehouse: Warehouse): Mono<Warehouse> {
        if (id <= 0) return Mono.error(InvalidDataException("El ID debe ser un número positivo."))
        return Mono.fromCallable {
            WarehouseValidator.validate(warehouse)
            warehouse
        }.flatMap {
            warehouseRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("La bodega con ID $id no existe.")))
        }.flatMap { existingWarehouse ->
            val updatedWarehouse = existingWarehouse.copy(
                name = warehouse.name,
                location = warehouse.location
            )
            warehouseRepository.save(updatedWarehouse)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) return Mono.error(InvalidDataException("El ID debe ser un número positivo."))
        return warehouseRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: la bodega con ID $id no existe.")))
            .flatMap { warehouseRepository.deleteById(id) }
            .onErrorMap { ex ->
                when (ex) {
                    is DataIntegrityViolationException ->
                        ReferentialIntegrityException("No se puede eliminar la bodega porque existen movimientos de stock asociados.")

                    else -> ex
                }
            }
    }

    fun findByName(name: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Warehouse> {
        if (name.isBlank()) return Flux.error(InvalidDataException("El nombre de la bodega no puede estar vacío."))
        return warehouseRepository.findByName(name, page, size)
    }

    fun findByNameContaining(name: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Warehouse> {
        if (name.isBlank()) return Flux.error(InvalidDataException("El nombre de la bodega no puede estar vacío."))
        return warehouseRepository.findByNameContaining(name, page, size)
    }

    fun findByLocation(location: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Warehouse> {
        if (location.isBlank()) return Flux.error(InvalidDataException("La ubicación no puede estar vacía."))
        return warehouseRepository.findByLocation(location, page, size)
    }
}