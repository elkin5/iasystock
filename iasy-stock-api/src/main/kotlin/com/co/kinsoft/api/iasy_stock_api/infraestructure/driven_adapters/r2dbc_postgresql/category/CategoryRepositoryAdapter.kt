package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.category

import com.co.kinsoft.api.iasy_stock_api.domain.model.category.Category
import com.co.kinsoft.api.iasy_stock_api.domain.model.category.gateway.CategoryRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Repository
class CategoryRepositoryAdapter(
    private val categoryDAORepository: CategoryDAORepository,
    private val categoryMapper: CategoryMapper
) : CategoryRepository {

    override fun findAll(page: Int, size: Int): Flux<Category> {
        return categoryDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { categoryMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Category> {
        return categoryDAORepository.findById(id)
            .map { categoryMapper.toDomain(it) }
    }

    override fun save(category: Category): Mono<Category> {
        val categoryDAO = categoryMapper.toDAO(category)
        return categoryDAORepository.save(categoryDAO)
            .map { categoryMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return categoryDAORepository.deleteById(id)
    }

    override fun findByName(name: String, page: Int, size: Int): Flux<Category> {
        return categoryDAORepository.findByName(name)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { categoryMapper.toDomain(it) }
    }

    override fun findByNameContaining(name: String, page: Int, size: Int): Flux<Category> {
        return categoryDAORepository.findByNameContainingIgnoreCase(name)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { categoryMapper.toDomain(it) }
    }
}