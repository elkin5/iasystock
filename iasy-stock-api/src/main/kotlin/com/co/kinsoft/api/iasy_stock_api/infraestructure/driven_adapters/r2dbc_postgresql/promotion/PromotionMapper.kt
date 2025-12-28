package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.promotion

import com.co.kinsoft.api.iasy_stock_api.domain.model.promotion.Promotion
import org.mapstruct.Mapper

@Mapper(componentModel = "spring")
interface PromotionMapper {
    fun toDomain(promotionDAO: PromotionDAO): Promotion
    fun toDAO(promotion: Promotion): PromotionDAO
}