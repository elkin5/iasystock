package com.co.kinsoft.api.iasy_stock_api.domain.usecase.category

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.DomainException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.category.Category
import com.co.kinsoft.api.iasy_stock_api.domain.model.category.gateway.CategoryRepository
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.product.ProductUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.promotion.PromotionUseCase
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

class CategoryUseCase(
    private val categoryRepository: CategoryRepository,
    private val productUseCase: ProductUseCase,
    private val promotionUseCase: PromotionUseCase
) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Category> =
        categoryRepository.findAll(page, size)

    fun findById(id: Long): Mono<Category> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return categoryRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La categoría con ID $id no existe.")))
    }

    fun create(category: Category): Mono<Category> {
        return Mono.fromCallable {
            CategoryValidator.validate(category)
            category
        }.flatMap {
            categoryRepository.findByName(category.name, DEFAULT_PAGE, DEFAULT_SIZE)
                .hasElements()
                .flatMap { exists ->
                    if (exists) {
                        Mono.error(AlreadyExistsException("Ya existe una categoría con el nombre '${category.name}'"))
                    } else {
                        categoryRepository.save(category)
                    }
                }
        }
    }

    fun update(id: Long, category: Category): Mono<Category> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            CategoryValidator.validate(category)
            category
        }.flatMap {
            categoryRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("La categoría con ID $id no existe.")))
        }.flatMap { existingCategory ->
            val updatedCategory = existingCategory.copy(
                name = category.name,
                description = category.description
            )
            categoryRepository.save(updatedCategory)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return categoryRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La categoría con ID $id no existe.")))
            .flatMap { category ->
                Mono.zip(
                    productUseCase.findByCategoryId(category.id).hasElements(),
                    promotionUseCase.findByCategoryId(category.id, 0, 1).hasElements()
                ).flatMap { tuple ->
                    val hasProducts = tuple.t1
                    val hasPromotions = tuple.t2
                    when {
                        hasProducts -> Mono.error(DomainException("No se puede eliminar: la categoría tiene productos asociados."))
                        hasPromotions -> Mono.error(DomainException("No se puede eliminar: la categoría tiene promociones asociadas."))
                        else -> categoryRepository.deleteById(id)
                    }
                }
            }
    }

    fun findByName(name: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Category> {
        if (name.isBlank()) {
            return Flux.error(InvalidDataException("El nombre de la categoría no puede estar en blanco."))
        }
        return categoryRepository.findByName(name, page, size)
    }

    fun findByNameContaining(name: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Category> {
        if (name.isBlank()) {
            return Flux.error(InvalidDataException("El nombre de la categoría no puede estar en blanco."))
        }
        return categoryRepository.findByNameContaining(name, page, size)
    }
}