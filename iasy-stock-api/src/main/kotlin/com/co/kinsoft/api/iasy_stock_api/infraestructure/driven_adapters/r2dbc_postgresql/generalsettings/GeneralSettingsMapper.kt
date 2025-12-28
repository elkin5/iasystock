package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.generalsettings

import com.co.kinsoft.api.iasy_stock_api.domain.model.generalsettings.GeneralSettings
import org.mapstruct.Mapper

@Mapper(componentModel = "spring")
interface GeneralSettingsMapper {
    fun toDomain(generalSettingsDAO: GeneralSettingsDAO): GeneralSettings
    fun toDAO(generalSettings: GeneralSettings): GeneralSettingsDAO
}