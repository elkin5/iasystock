package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.user

import com.co.kinsoft.api.iasy_stock_api.domain.model.user.User
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface UserMapper {
    fun toDomain(userDAO: UserDAO): User
    fun toDAO(user: User): UserDAO
}