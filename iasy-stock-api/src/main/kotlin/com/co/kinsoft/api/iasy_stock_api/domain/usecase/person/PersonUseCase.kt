package com.co.kinsoft.api.iasy_stock_api.domain.usecase.person

import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_PAGE
import com.co.kinsoft.api.iasy_stock_api.domain.common.PaginationDefaults.DEFAULT_SIZE
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.AlreadyExistsException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.DomainException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.InvalidDataException
import com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions.NotFoundException
import com.co.kinsoft.api.iasy_stock_api.domain.model.person.Person
import com.co.kinsoft.api.iasy_stock_api.domain.model.person.gateway.PersonRepository
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.sale.SaleUseCase
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.stock.StockUseCase
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

class PersonUseCase(
    private val personRepository: PersonRepository,
    private val stockUseCase: StockUseCase,
    private val saleUseCase: SaleUseCase
) {

    fun findAll(page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Person> =
        personRepository.findAll(page, size)

    fun findById(id: Long): Mono<Person> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return personRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("La persona con ID $id no existe.")))
    }

    fun create(person: Person): Mono<Person> {
        return Mono.fromCallable {
            PersonValidator.validate(person)
            person
        }.flatMap {
            Mono.zip(
                personRepository.findByIdentification(person.identification).hasElement(),
                personRepository.findByEmail(person.email).hasElement()
            ).flatMap { tuple ->
                val identExists = tuple.t1
                val emailExists = tuple.t2

                when {
                    identExists -> Mono.error(AlreadyExistsException("Ya existe una persona con el documento '${person.identification}'"))
                    emailExists -> Mono.error(AlreadyExistsException("Ya existe una persona con el correo '${person.email}'"))
                    else -> personRepository.save(person)
                }
            }
        }
    }

    fun update(id: Long, person: Person): Mono<Person> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return Mono.fromCallable {
            PersonValidator.validate(person)
            person
        }.flatMap {
            personRepository.findById(id)
                .switchIfEmpty(Mono.error(NotFoundException("La persona con ID $id no existe.")))
        }.flatMap { existingPerson ->
            val updatedPerson = existingPerson.copy(
                name = person.name,
                identification = person.identification,
                identificationType = person.identificationType,
                cellPhone = person.cellPhone,
                email = person.email,
                address = person.address,
                type = person.type
            )
            personRepository.save(updatedPerson)
        }
    }

    fun delete(id: Long): Mono<Void> {
        if (id <= 0) {
            return Mono.error(InvalidDataException("El ID debe ser un valor positivo."))
        }
        return personRepository.findById(id)
            .switchIfEmpty(Mono.error(NotFoundException("No se puede eliminar: la persona con ID $id no existe.")))
            .flatMap { person ->
                Mono.zip(
                    stockUseCase.findByPersonId(id, 0, 1).hasElements(),
                    saleUseCase.findByPersonId(id, 0, 1).hasElements()
                ).flatMap { tuple ->
                    val hasStock = tuple.t1
                    val hasSales = tuple.t2
                    when {
                        hasStock -> Mono.error(DomainException("No se puede eliminar: la persona tiene registros en inventario."))
                        hasSales -> Mono.error(DomainException("No se puede eliminar: la persona tiene ventas asociadas."))
                        else -> personRepository.deleteById(id)
                    }
                }
            }
    }

    fun findByName(name: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Person> {
        if (name.isBlank()) {
            return Flux.error(InvalidDataException("El nombre no puede estar en blanco."))
        }
        return personRepository.findByName(name, page, size)
    }

    fun findByIdentification(identification: Long): Mono<Person> {
        if (identification <= 0) {
            return Mono.error(InvalidDataException("La identificación debe ser un número positivo."))
        }
        return personRepository.findByIdentification(identification)
            .switchIfEmpty(Mono.error(NotFoundException("No se encontró persona con identificación $identification.")))
    }

    fun findByType(type: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Person> {
        if (type.isBlank()) {
            return Flux.error(InvalidDataException("El tipo de persona no puede estar en blanco."))
        }
        return personRepository.findByType(type, page, size)
    }

    fun findByEmail(email: String): Mono<Person> {
        if (email.isBlank()) {
            return Mono.error(InvalidDataException("El correo electrónico no puede estar en blanco."))
        }
        return personRepository.findByEmail(email)
            .switchIfEmpty(Mono.error(NotFoundException("No se encontró persona con correo '$email'.")))
    }

    fun findByNameContaining(keyword: String, page: Int = DEFAULT_PAGE, size: Int = DEFAULT_SIZE): Flux<Person> {
        if (keyword.isBlank()) {
            return Flux.error(InvalidDataException("El texto de búsqueda no puede estar en blanco."))
        }
        return personRepository.findByNameContaining(keyword, page, size)
    }
}