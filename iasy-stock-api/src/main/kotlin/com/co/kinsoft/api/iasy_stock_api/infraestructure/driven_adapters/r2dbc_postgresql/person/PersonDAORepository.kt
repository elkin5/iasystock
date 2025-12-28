package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.person

import org.springframework.data.repository.reactive.ReactiveCrudRepository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

interface PersonDAORepository : ReactiveCrudRepository<PersonDAO, Long> {
    fun findByName(name: String): Flux<PersonDAO>
    fun findByIdentification(identification: Long?): Mono<PersonDAO>
    fun findByType(type: String): Flux<PersonDAO>
    fun findByEmail(email: String?): Mono<PersonDAO>
    fun findByNameContaining(keyword: String): Flux<PersonDAO>
}