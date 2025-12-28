package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.stock

import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface StockMapper {
    fun toDomain(stockDAO: StockDAO): Stock
    fun toDAO(stock: Stock): StockDAO
}