package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.category

import com.co.kinsoft.api.iasy_stock_api.domain.model.category.Category
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface CategoryMapper {
    fun toDomain(categoryDAO: CategoryDAO): Category
    fun toDAO(category: Category): CategoryDAO
}