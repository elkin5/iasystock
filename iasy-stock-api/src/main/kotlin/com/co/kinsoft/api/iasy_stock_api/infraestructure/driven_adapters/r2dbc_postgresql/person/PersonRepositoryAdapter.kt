package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.person

import com.co.kinsoft.api.iasy_stock_api.domain.model.person.Person
import com.co.kinsoft.api.iasy_stock_api.domain.model.person.gateway.PersonRepository
import org.springframework.stereotype.Repository
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Repository
class PersonRepositoryAdapter(
    private val personDAORepository: PersonDAORepository,
    private val personMapper: PersonMapper
) : PersonRepository {

    override fun findAll(page: Int, size: Int): Flux<Person> {
        return personDAORepository.findAll()
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { personMapper.toDomain(it) }
    }

    override fun findById(id: Long): Mono<Person> {
        return personDAORepository.findById(id)
            .map { personMapper.toDomain(it) }
    }

    override fun save(person: Person): Mono<Person> {
        val personDAO = personMapper.toDAO(person)
        return personDAORepository.save(personDAO)
            .map { personMapper.toDomain(it) }
    }

    override fun deleteById(id: Long): Mono<Void> {
        return personDAORepository.deleteById(id)
    }

    override fun findByName(name: String, page: Int, size: Int): Flux<Person> {
        return personDAORepository.findByName(name)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { personMapper.toDomain(it) }
    }

    override fun findByIdentification(identification: Long?): Mono<Person> {
        return personDAORepository.findByIdentification(identification)
            .map { personMapper.toDomain(it) }
    }

    override fun findByType(type: String, page: Int, size: Int): Flux<Person> {
        return personDAORepository.findByType(type)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { personMapper.toDomain(it) }
    }

    override fun findByEmail(email: String?): Mono<Person> {
        return personDAORepository.findByEmail(email)
            .map { personMapper.toDomain(it) }
    }

    override fun findByNameContaining(keyword: String, page: Int, size: Int): Flux<Person> {
        return personDAORepository.findByNameContaining(keyword)
            .sort(compareByDescending { it.id })
            .skip((page * size).toLong())
            .take(size.toLong())
            .map { personMapper.toDomain(it) }
    }
}