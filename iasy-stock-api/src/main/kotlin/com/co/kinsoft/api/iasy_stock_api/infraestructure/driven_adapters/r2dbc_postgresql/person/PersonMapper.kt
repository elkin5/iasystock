package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.person

import com.co.kinsoft.api.iasy_stock_api.domain.model.person.Person
import org.mapstruct.Mapper

@Mapper(componentModel = "spring")
interface PersonMapper {
    fun toDomain(personDAO: PersonDAO): Person
    fun toDAO(person: Person): PersonDAO
}