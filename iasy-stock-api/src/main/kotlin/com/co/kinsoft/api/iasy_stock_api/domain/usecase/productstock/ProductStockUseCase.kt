package com.co.kinsoft.api.iasy_stock_api.domain.usecase.productstock

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import reactor.core.publisher.Mono

/**
 * Servicio para manejar la actualización automática del stock de productos
 * basado en movimientos de Stock y SaleItem
 */

class ProductStockUseCase(
  private val productRepository: ProductRepository
) {

  private val logger: Logger = LoggerFactory.getLogger(ProductStockUseCase::class.java)

  /**
   * Actualiza el stock de un producto sumando la cantidad especificada
   * @param productId ID del producto
   * @param quantityChange Cantidad a sumar (positiva para entradas, negativa para salidas)
   * @return Mono<Void> cuando la actualización se complete
   */
  fun updateProductStock(productId: Long, quantityChange: Int): Mono<Void> {
    if (quantityChange == 0) {
      logger.debug("No hay cambio en la cantidad para el producto $productId")
      return Mono.empty()
    }

    logger.info("Actualizando stock del producto $productId con cambio de $quantityChange unidades")

    return productRepository.findById(productId)
      .switchIfEmpty(Mono.error(IllegalArgumentException("Producto con ID $productId no encontrado")))
      .flatMap { product ->
        val currentStock = product.stockQuantity ?: 0
        val newStock = currentStock + quantityChange

        // Asegurar que el stock no sea negativo
        val finalStock = if (newStock < 0) {
          logger.warn("Stock negativo detectado para producto $productId. Ajustando a 0")
          0
        } else {
          newStock
        }

        logger.info("Stock del producto $productId: $currentStock -> $finalStock (cambio: $quantityChange)")

        productRepository.updateStockQuantity(productId, finalStock)
      }
      .doOnSuccess {
        logger.info("Stock del producto $productId actualizado exitosamente")
      }
      .doOnError { error ->
        logger.error("Error actualizando stock del producto $productId: ${error.message}", error)
      }
  }

  /**
   * Incrementa el stock de un producto (para entradas de Stock)
   * @param productId ID del producto
   * @param quantity Cantidad a incrementar
   */
  fun incrementProductStock(productId: Long, quantity: Int): Mono<Void> {
    return updateProductStock(productId, quantity)
  }

  /**
   * Decrementa el stock de un producto (para ventas de SaleItem)
   * @param productId ID del producto
   * @param quantity Cantidad a decrementar
   */
  fun decrementProductStock(productId: Long, quantity: Int): Mono<Void> {
    return updateProductStock(productId, -quantity)
  }
}