package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.sale

import com.co.kinsoft.api.iasy_stock_api.domain.model.sale.Sale
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface SaleMapper {
    fun toDomain(saleDAO: SaleDAO): Sale
    fun toDAO(sale: Sale): SaleDAO
}