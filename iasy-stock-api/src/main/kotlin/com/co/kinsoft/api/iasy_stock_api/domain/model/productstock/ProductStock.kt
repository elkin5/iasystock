package com.co.kinsoft.api.iasy_stock_api.domain.model.productstock

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import com.co.kinsoft.api.iasy_stock_api.domain.model.stock.Stock

/**
 * Modelo agregador para representar un producto junto a sus movimientos de stock.
 */
data class ProductStock(
    val product: Product,
    val stocks: List<Stock>
) {
    fun hasStocks(): Boolean = stocks.isNotEmpty()

    fun isValid(): Boolean = product.isValid() && stocks.all { it.productId == 0L || it.productId == product.id }

    fun totalQuantity(): Int = stocks.sumOf { it.quantity }

    fun uniqueWarehouses(): Int = stocks.mapNotNull { it.warehouseId }.distinct().size
}
