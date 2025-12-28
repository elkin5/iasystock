package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.warehouse

import com.co.kinsoft.api.iasy_stock_api.domain.model.warehouse.Warehouse
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface WarehouseMapper {
    fun toDomain(warehouseDAO: WarehouseDAO): Warehouse
    fun toDAO(warehouse: Warehouse): WarehouseDAO
}