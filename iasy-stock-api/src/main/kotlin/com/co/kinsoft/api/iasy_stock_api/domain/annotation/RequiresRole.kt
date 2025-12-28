package com.co.kinsoft.api.iasy_stock_api.domain.annotation

/**
 * Anotación para especificar roles requeridos en métodos de controlador
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresRole(
    val roles: Array<String>,
    val requireAll: Boolean = false
)

/**
 * Anotación para especificar que se requiere rol de super usuario
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresSudo

/**
 * Anotación para especificar que se requiere rol de administrador
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresAdmin

/**
 * Anotación para especificar que se requiere acceso a inventario
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresInventoryAccess

/**
 * Anotación para especificar que se requiere acceso a ventas
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresSalesAccess

/**
 * Anotación para especificar que se requiere acceso a reportes
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresReportsAccess

/**
 * Anotación para especificar que se requiere acceso a auditoría
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequiresAuditAccess

