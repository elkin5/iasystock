package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.saleitem

import com.co.kinsoft.api.iasy_stock_api.domain.model.saleitem.SaleItem
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface SaleItemMapper {
    fun toDomain(saleItemDAO: SaleItemDAO): SaleItem
    fun toDAO(saleItem: SaleItem): SaleItemDAO
}