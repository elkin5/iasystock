package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.product

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import org.mapstruct.Mapper

@Mapper(componentModel = "spring")
interface ProductMapper {
    fun toDomain(productDAO: ProductDAO): Product
    fun toDAO(product: Product): ProductDAO
}