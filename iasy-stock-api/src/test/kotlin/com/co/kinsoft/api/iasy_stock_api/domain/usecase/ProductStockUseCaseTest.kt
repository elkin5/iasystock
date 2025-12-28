package com.co.kinsoft.api.iasy_stock_api.domain.usecase

import com.co.kinsoft.api.iasy_stock_api.domain.model.product.Product
import com.co.kinsoft.api.iasy_stock_api.domain.model.product.gateway.ProductRepository
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.productstock.ProductStockUseCase
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.ArgumentMatchers
import org.mockito.Mock
import org.mockito.Mockito
import org.mockito.junit.jupiter.MockitoExtension
import reactor.core.publisher.Mono
import reactor.test.StepVerifier
import java.time.LocalDateTime

@ExtendWith(MockitoExtension::class)
class ProductStockUseCaseTest {

  @Mock
  private lateinit var productRepository: ProductRepository

  @Test
  fun `debe incrementar el stock del producto correctamente`() {
    // Arrange
    val productId = 1L
    val currentStock = 10
    val incrementAmount = 5
    val expectedStock = 15

    val product = Product(
        id = productId,
        name = "Producto Test",
        categoryId = 1L,
        stockQuantity = currentStock,
        createdAt = LocalDateTime.now()
    )

    Mockito.`when`(productRepository.findById(productId)).thenReturn(Mono.just(product))
    Mockito.`when`(productRepository.updateStockQuantity(productId, expectedStock)).thenReturn(Mono.empty())

    val service = ProductStockUseCase(productRepository)

    // Act & Assert
    StepVerifier.create(service.incrementProductStock(productId, incrementAmount))
      .verifyComplete()

    Mockito.verify(productRepository).findById(productId)
    Mockito.verify(productRepository).updateStockQuantity(productId, expectedStock)
  }

  @Test
  fun `debe decrementar el stock del producto correctamente`() {
    // Arrange
    val productId = 1L
    val currentStock = 20
    val decrementAmount = 3
    val expectedStock = 17

    val product = Product(
        id = productId,
        name = "Producto Test",
        categoryId = 1L,
        stockQuantity = currentStock,
        createdAt = LocalDateTime.now()
    )

    Mockito.`when`(productRepository.findById(productId)).thenReturn(Mono.just(product))
    Mockito.`when`(productRepository.updateStockQuantity(productId, expectedStock)).thenReturn(Mono.empty())

    val service = ProductStockUseCase(productRepository)

    // Act & Assert
    StepVerifier.create(service.decrementProductStock(productId, decrementAmount))
      .verifyComplete()

    Mockito.verify(productRepository).findById(productId)
    Mockito.verify(productRepository).updateStockQuantity(productId, expectedStock)
  }

  @Test
  fun `debe ajustar stock negativo a cero`() {
    // Arrange
    val productId = 1L
    val currentStock = 2
    val decrementAmount = 5
    val expectedStock = 0 // Debe ajustarse a 0

    val product = Product(
        id = productId,
        name = "Producto Test",
        categoryId = 1L,
        stockQuantity = currentStock,
        createdAt = LocalDateTime.now()
    )

    Mockito.`when`(productRepository.findById(productId)).thenReturn(Mono.just(product))
    Mockito.`when`(productRepository.updateStockQuantity(productId, expectedStock)).thenReturn(Mono.empty())

    val service = ProductStockUseCase(productRepository)

    // Act & Assert
    StepVerifier.create(service.decrementProductStock(productId, decrementAmount))
      .verifyComplete()

    Mockito.verify(productRepository).findById(productId)
    Mockito.verify(productRepository).updateStockQuantity(productId, expectedStock)
  }

  @Test
  fun `debe manejar producto no encontrado`() {
    // Arrange
    val productId = 999L
    val incrementAmount = 5

    Mockito.`when`(productRepository.findById(productId)).thenReturn(Mono.empty())

    val service = ProductStockUseCase(productRepository)

    // Act & Assert
    StepVerifier.create(service.incrementProductStock(productId, incrementAmount))
      .expectError(IllegalArgumentException::class.java)
      .verify()

    Mockito.verify(productRepository).findById(productId)
    Mockito.verify(productRepository, Mockito.never())
        .updateStockQuantity(ArgumentMatchers.anyLong(), ArgumentMatchers.anyInt())
  }

  @Test
  fun `debe manejar cambio de cantidad cero`() {
    // Arrange
    val productId = 1L
    val changeAmount = 0

    val service = ProductStockUseCase(productRepository)

    // Act & Assert
    StepVerifier.create(service.updateProductStock(productId, changeAmount))
      .verifyComplete()

    Mockito.verify(productRepository, Mockito.never()).findById(ArgumentMatchers.anyLong())
    Mockito.verify(productRepository, Mockito.never())
        .updateStockQuantity(ArgumentMatchers.anyLong(), ArgumentMatchers.anyInt())
  }
}