package com.co.kinsoft.api.iasy_stock_api.domain.model.person.gateway

import com.co.kinsoft.api.iasy_stock_api.domain.model.person.Person
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface PersonRepository {
    fun findAll(page: Int, size: Int): Flux<Person>
    fun findById(id: Long): Mono<Person>
    fun save(person: Person): Mono<Person>
    fun deleteById(id: Long): Mono<Void>

    // Métodos de búsqueda con paginación
    fun findByName(name: String, page: Int, size: Int): Flux<Person>
    fun findByIdentification(identification: Long?): Mono<Person>
    fun findByType(type: String, page: Int, size: Int): Flux<Person>
    fun findByEmail(email: String?): Mono<Person>
    fun findByNameContaining(keyword: String, page: Int, size: Int): Flux<Person>
}