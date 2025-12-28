package com.co.kinsoft.api.iasy_stock_api.domain.common.exceptions

open class DomainException(message: String) : RuntimeException(message)

class NotFoundException(message: String) : DomainException(message)
class AlreadyExistsException(message: String) : DomainException(message)
class InvalidDataException(message: String) : DomainException(message)
class NullFieldException(message: String) : DomainException(message)
class EmailFormatException(message: String) : DomainException(message)
class ReferentialIntegrityException(message: String) : DomainException(message)