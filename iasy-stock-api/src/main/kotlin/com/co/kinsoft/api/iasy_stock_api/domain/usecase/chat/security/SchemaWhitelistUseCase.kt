package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.security

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import reactor.core.publisher.Mono

/**
 * Use case para validar que los queries solo accedan a tablas y columnas permitidas
 * Implementa una whitelist de schema para prevenir acceso no autorizado
 */
@Service
class SchemaWhitelistUseCase(
    private val securityAuditLogger: SecurityAuditLogger
) {

    private val logger = LoggerFactory.getLogger(SchemaWhitelistUseCase::class.java)

    companion object {
        // Schema permitido
        const val ALLOWED_SCHEMA = "schmain"

        // Tablas permitidas y sus columnas
        // NOTA: Incluye tanto nombres legacy como nombres reales de la DB para compatibilidad
        val ALLOWED_TABLES = mapOf(
            "product" to setOf(
                // Columnas reales de la DB
                "product_id", "name", "description", "product_image", "image_url",
                "category_id", "stock_quantity", "stock_minimum", "created_at",
                "expiration_date", "barcode_data", "brand_name", "model_number",
                "dominant_colors", "text_ocr",
                // Nombres legacy para compatibilidad con queries existentes
                "id", "price", "min_stock", "max_stock", "barcode",
                "sku", "is_active", "updated_at"
            ),
            "category" to setOf(
                // Columnas reales de la DB
                "category_id", "name", "description",
                // Nombres legacy
                "id", "parent_category_id", "is_active", "created_at", "updated_at"
            ),
            "sale" to setOf(
                // Columnas reales de la DB
                "sale_id", "person_id", "user_id", "total_amount",
                "sale_date", "pay_method", "state", "created_at",
                // Nombres legacy
                "id", "discount_amount", "tax_amount", "net_amount",
                "payment_method", "customer_id", "status", "updated_at"
            ),
            "saleitem" to setOf(
                // Columnas reales de la DB
                "sale_item_id", "sale_id", "product_id", "quantity",
                "unit_price", "total_price",
                // Nombres legacy
                "id", "subtotal", "discount", "created_at"
            ),
            "stock" to setOf(
                // Columnas reales de la DB
                "stock_id", "quantity", "entry_price", "sale_price",
                "product_id", "user_id", "warehouse_id", "person_id",
                "entry_date", "created_at",
                // Nombres legacy
                "id", "movement_type", "movement_date", "reference",
                "notes", "price"
            ),
            "warehouse" to setOf(
                "id", "name", "location", "description",
                "is_active", "created_at", "updated_at"
            ),
            "person" to setOf(
                "id", "first_name", "last_name", "email",
                "phone", "document_type", "document_number",
                "address", "city", "country", "is_active",
                "created_at", "updated_at"
            ),
            "promotion" to setOf(
                "id", "name", "description", "discount_type",
                "discount_value", "start_date", "end_date",
                "is_active", "created_at", "updated_at"
            ),
            "user" to setOf(
                // Columnas de la tabla user
                "id", "user_id", "username", "email", "password_hash",
                "first_name", "last_name", "role", "is_active",
                "created_at", "updated_at", "last_login"
            ),
            "auditlog" to setOf(
                "id", "audit_id", "user_id", "action", "entity_type",
                "entity_id", "old_value", "new_value", "ip_address",
                "created_at", "timestamp"
            )
        )

        // Funciones SQL permitidas (y palabras clave que el parser detecta como funciones)
        val ALLOWED_FUNCTIONS = setOf(
            // Funciones agregadas
            "count", "sum", "avg", "max", "min",
            // Funciones de string
            "upper", "lower", "trim", "concat",
            // Funciones de fecha
            "date", "now", "current_date", "current_timestamp", "date_trunc",
            // Funciones de utilidad
            "coalesce", "nullif", "cast", "round",
            // Palabras clave SQL que el parser puede detectar como funciones
            "case", "when", "then", "end", "else"
        )

        // Palabras clave peligrosas en contexto de tablas del sistema
        // NOTA: "user" fue removido porque es una tabla válida en schmain
        val SYSTEM_TABLES = setOf(
            "pg_", "information_schema", "pg_catalog",
            "pg_user", "pg_shadow", "pg_roles",
            "pg_database", "pg_tables", "pg_class"
        )
    }

    /**
     * Valida que el query solo acceda a tablas y columnas permitidas
     */
    fun validateSchemaAccess(
        query: String,
        userId: Long,
        sessionId: String?
    ): Mono<SchemaValidationResult> {
        return Mono.fromCallable {
            logger.debug("Validando acceso a schema para usuario: $userId")

            val normalizedQuery = query.lowercase().trim()

            // 1. Verificar que use el schema correcto
            val schemaCheck = validateSchemaUsage(normalizedQuery)
            if (!schemaCheck.isValid) {
                logSchemaViolation(userId, sessionId, query, schemaCheck.reason!!)
                return@fromCallable schemaCheck
            }

            // 2. Extraer tablas referenciadas
            val referencedTables = extractTableNames(normalizedQuery)
            logger.debug("Tablas detectadas: $referencedTables")

            // 3. Verificar que todas las tablas estén en la whitelist
            val unauthorizedTables = referencedTables.filter { table ->
                !ALLOWED_TABLES.containsKey(table)
            }

            if (unauthorizedTables.isNotEmpty()) {
                val reason = "Acceso a tablas no autorizadas: ${unauthorizedTables.joinToString(", ")}"
                logger.warn("Acceso no autorizado detectado (usuario: $userId): $reason")
                logSchemaViolation(userId, sessionId, query, reason)

                return@fromCallable SchemaValidationResult(
                    isValid = false,
                    reason = reason,
                    violationType = SchemaViolationType.UNAUTHORIZED_TABLE
                )
            }

            // 4. Verificar que no acceda a tablas del sistema
            // Usar regex para evitar falsos positivos (ej: "user_id" no debe confundirse con tabla "user")
            val systemTableAccess = SYSTEM_TABLES.any { sysTable ->
                when {
                    // Para prefijos como "pg_", verificar que aparezca como inicio de palabra
                    sysTable.endsWith("_") -> normalizedQuery.contains(sysTable)
                    // Para nombres completos, verificar que sea una tabla (FROM/JOIN) y no parte de columna
                    else -> {
                        val tablePattern = Regex("(?:from|join)\\s+(?:schmain\\.)?$sysTable(?:\\s|$|\\)|,)")
                        tablePattern.containsMatchIn(normalizedQuery)
                    }
                }
            }

            if (systemTableAccess) {
                val reason = "Intento de acceso a tablas del sistema"
                logger.warn("Intento de acceso a tablas del sistema (usuario: $userId)")
                logSchemaViolation(userId, sessionId, query, reason)

                return@fromCallable SchemaValidationResult(
                    isValid = false,
                    reason = reason,
                    violationType = SchemaViolationType.SYSTEM_TABLE_ACCESS
                )
            }

            // 5. Verificar columnas si es posible (análisis básico)
            val columnValidation = validateColumns(normalizedQuery, referencedTables)
            if (!columnValidation.isValid) {
                logSchemaViolation(userId, sessionId, query, columnValidation.reason!!)
                return@fromCallable columnValidation
            }

            // 6. Verificar funciones SQL
            val functionValidation = validateFunctions(normalizedQuery)
            if (!functionValidation.isValid) {
                logSchemaViolation(userId, sessionId, query, functionValidation.reason!!)
                return@fromCallable functionValidation
            }

            logger.debug("Validación de schema exitosa para usuario: $userId")
            SchemaValidationResult(
                isValid = true,
                reason = null,
                violationType = null
            )
        }
    }

    /**
     * Valida que use el schema correcto
     */
    private fun validateSchemaUsage(query: String): SchemaValidationResult {
        // Verificar que mencione schmain o que no especifique schema (se asume schmain por defecto)
        val hasSchemaPrefix = Regex("from\\s+([a-z_]+)\\.").containsMatchIn(query)

        if (hasSchemaPrefix) {
            val wrongSchema = !query.contains("$ALLOWED_SCHEMA.")
            if (wrongSchema) {
                return SchemaValidationResult(
                    isValid = false,
                    reason = "Query debe usar el schema '$ALLOWED_SCHEMA'",
                    violationType = SchemaViolationType.WRONG_SCHEMA
                )
            }
        }

        return SchemaValidationResult(isValid = true, reason = null, violationType = null)
    }

    /**
     * Extrae nombres de tablas del query
     * Soporta: FROM schema.table, FROM schema."table", FROM table
     */
    private fun extractTableNames(query: String): Set<String> {
        val tables = mutableSetOf<String>()

        // Pattern mejorado que maneja comillas dobles: schema."table" o schema.table
        // Captura el nombre de tabla con o sin comillas
        val fromPattern = Regex("from\\s+(?:$ALLOWED_SCHEMA\\.)?(?:\"|\\\\\")?([a-z_]+)(?:\"|\\\\\")?", RegexOption.IGNORE_CASE)
        fromPattern.findAll(query).forEach { match ->
            val tableName = match.groupValues[1].lowercase()
            if (tableName != ALLOWED_SCHEMA) { // No agregar "schmain" como tabla
                tables.add(tableName)
            }
        }

        // Pattern para JOIN con soporte de comillas
        val joinPattern = Regex("join\\s+(?:$ALLOWED_SCHEMA\\.)?(?:\"|\\\\\")?([a-z_]+)(?:\"|\\\\\")?", RegexOption.IGNORE_CASE)
        joinPattern.findAll(query).forEach { match ->
            val tableName = match.groupValues[1].lowercase()
            if (tableName != ALLOWED_SCHEMA) { // No agregar "schmain" como tabla
                tables.add(tableName)
            }
        }

        return tables
    }

    /**
     * Valida columnas referenciadas (validación básica)
     * OPTIMIZACIÓN: Parser mejorado que ignora expresiones SQL complejas
     */
    private fun validateColumns(query: String, tables: Set<String>): SchemaValidationResult {
        // Si hay una sola tabla, podemos validar columnas más estrictamente
        if (tables.size == 1) {
            val table = tables.first()
            val allowedColumns = ALLOWED_TABLES[table] ?: return SchemaValidationResult(
                isValid = true,
                reason = null,
                violationType = null
            )

            // Extraer columnas del SELECT (análisis simplificado)
            val selectPattern = Regex("select\\s+(.*?)\\s+from", RegexOption.IGNORE_CASE)
            val selectMatch = selectPattern.find(query)

            if (selectMatch != null) {
                val selectClause = selectMatch.groupValues[1]

                // Si es SELECT *, permitir
                if (selectClause.trim() == "*") {
                    return SchemaValidationResult(isValid = true, reason = null, violationType = null)
                }

                // Extraer solo nombres de columnas simples (no expresiones SQL)
                val columns = selectClause.split(",")
                    .map { it.trim() }
                    .mapNotNull { col ->
                        extractColumnName(col)
                    }
                    .filter { it.isNotBlank() }

                // Verificar que columnas estén en la whitelist
                val invalidColumns = columns.filter { col ->
                    !allowedColumns.contains(col) && !col.contains(".")
                }

                if (invalidColumns.isNotEmpty()) {
                    return SchemaValidationResult(
                        isValid = false,
                        reason = "Columnas no autorizadas: ${invalidColumns.joinToString(", ")}",
                        violationType = SchemaViolationType.UNAUTHORIZED_COLUMN
                    )
                }
            }
        }

        return SchemaValidationResult(isValid = true, reason = null, violationType = null)
    }

    /**
     * Extrae el nombre de columna de una expresión SQL
     * Retorna null si la expresión es compleja (funciones agregadas, CASE WHEN, etc.)
     */
    private fun extractColumnName(expression: String): String? {
        var cleaned = expression.trim()

        // Remover alias (AS ...)
        cleaned = cleaned.replace(Regex("\\s+as\\s+.*", RegexOption.IGNORE_CASE), "").trim()

        // Si contiene CASE WHEN, es una expresión compleja, omitir validación
        if (cleaned.contains("case", ignoreCase = true)) {
            return null
        }

        // Si contiene múltiples paréntesis anidados, es una expresión compleja
        val openParens = cleaned.count { it == '(' }
        val closeParens = cleaned.count { it == ')' }
        if (openParens > 1 || closeParens > 1) {
            return null
        }

        // Si es una función agregada simple como COUNT(*), SUM(column), extraer columna
        val simpleFunctionPattern = Regex("([a-z_]+)\\s*\\(\\s*([a-z_*]+)\\s*\\)", RegexOption.IGNORE_CASE)
        val functionMatch = simpleFunctionPattern.find(cleaned)

        if (functionMatch != null) {
            val functionName = functionMatch.groupValues[1].lowercase()
            val columnName = functionMatch.groupValues[2].trim()

            // Si es COUNT(*), SUM(*), etc., no validar columna
            if (columnName == "*") {
                return null
            }

            // Si la función está permitida, retornar la columna dentro
            if (ALLOWED_FUNCTIONS.contains(functionName)) {
                return columnName
            }
        }

        // Si es una columna simple (nombre_columna), retornarla
        val simpleColumnPattern = Regex("^[a-z_][a-z0-9_]*$", RegexOption.IGNORE_CASE)
        if (simpleColumnPattern.matches(cleaned)) {
            return cleaned
        }

        // Si es table.column, extraer solo el nombre de columna
        val qualifiedColumnPattern = Regex("^[a-z_][a-z0-9_]*\\.([a-z_][a-z0-9_]*)$", RegexOption.IGNORE_CASE)
        val qualifiedMatch = qualifiedColumnPattern.find(cleaned)
        if (qualifiedMatch != null) {
            return qualifiedMatch.groupValues[1]
        }

        // Si no coincide con ningún patrón, omitir validación (puede ser expresión compleja)
        return null
    }

    /**
     * Valida funciones SQL usadas
     */
    private fun validateFunctions(query: String): SchemaValidationResult {
        // Extraer nombres de funciones
        val functionPattern = Regex("([a-z_]+)\\s*\\(")
        val functions = functionPattern.findAll(query)
            .map { it.groupValues[1] }
            .toSet()

        val unauthorizedFunctions = functions.filter { func ->
            !ALLOWED_FUNCTIONS.contains(func) &&
            !ALLOWED_TABLES.containsKey(func) && // No es nombre de tabla
            func.length > 2 // Ignorar palabras muy cortas
        }

        if (unauthorizedFunctions.isNotEmpty()) {
            return SchemaValidationResult(
                isValid = false,
                reason = "Funciones no autorizadas: ${unauthorizedFunctions.joinToString(", ")}",
                violationType = SchemaViolationType.UNAUTHORIZED_FUNCTION
            )
        }

        return SchemaValidationResult(isValid = true, reason = null, violationType = null)
    }

    /**
     * Registra violación de schema
     */
    private fun logSchemaViolation(
        userId: Long,
        sessionId: String?,
        query: String,
        reason: String
    ) {
        securityAuditLogger.logSecurityEvent(
            userId = userId,
            sessionId = sessionId,
            eventType = SecurityEventType.SCHEMA_VIOLATION,
            severity = SecuritySeverity.HIGH,
            description = "Violación de schema: $reason",
            additionalData = mapOf(
                "query" to query.take(500),
                "reason" to reason
            )
        )
    }

    /**
     * Obtiene información sobre tablas y columnas permitidas
     */
    fun getAllowedTablesInfo(): Map<String, Set<String>> {
        return ALLOWED_TABLES
    }

    /**
     * Verifica si una tabla específica está permitida
     */
    fun isTableAllowed(tableName: String): Boolean {
        return ALLOWED_TABLES.containsKey(tableName.lowercase())
    }

    /**
     * Verifica si una columna está permitida para una tabla
     */
    fun isColumnAllowed(tableName: String, columnName: String): Boolean {
        val allowedColumns = ALLOWED_TABLES[tableName.lowercase()] ?: return false
        return allowedColumns.contains(columnName.lowercase())
    }
}

/**
 * Resultado de validación de schema
 */
data class SchemaValidationResult(
    val isValid: Boolean,
    val reason: String?,
    val violationType: SchemaViolationType?
)

/**
 * Tipos de violaciones de schema
 */
enum class SchemaViolationType {
    WRONG_SCHEMA,
    UNAUTHORIZED_TABLE,
    UNAUTHORIZED_COLUMN,
    UNAUTHORIZED_FUNCTION,
    SYSTEM_TABLE_ACCESS
}
