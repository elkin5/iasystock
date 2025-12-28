package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat

import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.ErrorType
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.ValidationResult
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.ColumnInfo
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.ForeignKeyInfo
import com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.TableInfo
import org.springframework.r2dbc.core.DatabaseClient
import org.springframework.stereotype.Repository
import reactor.core.publisher.Mono

@Repository
class ChatRepository(
    private val databaseClient: DatabaseClient
) {

    private val logger = org.slf4j.LoggerFactory.getLogger(ChatRepository::class.java)

    /**
     * Validación con EXPLAIN para verificar que PostgreSQL pueda ejecutar el query
     */
    fun performExplainValidation(query: String): Mono<ValidationResult> {
        val explainQuery = "EXPLAIN $query"

        return databaseClient.sql(explainQuery)
            .fetch()
            .all()
            .collectList()
            .map { results ->
                if (results.isNotEmpty()) {
                    logger.debug("Query pasó validación EXPLAIN exitosamente")
                    ValidationResult(
                        isValid = true,
                        errorMessage = null,
                        errorType = null,
                        suggestion = null
                    )
                } else {
                    ValidationResult(
                        isValid = false,
                        errorMessage = "EXPLAIN no retornó resultados",
                        errorType = ErrorType.EXPLAIN_FAILED,
                        suggestion = "Verifica la sintaxis del query"
                    )
                }
            }
            .onErrorResume { error ->
                logger.warn("EXPLAIN falló: ${error.message}")

                // Analizar el error para proporcionar feedback específico
                val errorMsg = error.message ?: "Error desconocido"
                val (errorType, suggestion) = analyzePostgresError(errorMsg)

                Mono.just(
                    ValidationResult(
                        isValid = false,
                        errorMessage = errorMsg,
                        errorType = errorType,
                        suggestion = suggestion
                    )
                )
            }
    }

    /**
     * Ejecuta un query que ya fue validado
     */
    fun executeValidatedQuery(query: String): Mono<String> {
        return databaseClient.sql(query)
            .map { row, metadata ->
                val rowData = mutableMapOf<String, Any>()
                metadata.columnMetadatas.forEach { column ->
                    val columnName = column.name
                    val value = row.get(columnName)
                    rowData[columnName] = value ?: "null"
                }
                rowData
            }
            .all()
            .collectList()
            .map { results ->
                if (results.isEmpty()) {
                    "No se encontraron resultados para tu consulta."
                } else {
                    formatQueryResults(results, query)
                }
            }
    }

    /**
     * Obtiene la lista de tablas y sus comentarios en el esquema 'schmain'
     */
    fun getTablesInfo(): Mono<List<TableInfo>> {
        val query = """
            SELECT
                table_name,
                obj_description((table_schema || '.' || table_name)::regclass, 'pg_class') as table_comment
            FROM information_schema.tables
            WHERE table_schema = 'schmain'
            AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """.trimIndent()

        return databaseClient.sql(query)
            .map { row, _ ->
                TableInfo(
                    name = row.get("table_name", String::class.java) ?: "",
                    comment = row.get("table_comment", String::class.java)
                )
            }
            .all()
            .collectList()
    }

    /**
     * Obtiene la lista de columnas y sus detalles en el esquema 'schmain'
     */
    fun getColumnsInfo(): Mono<List<ColumnInfo>> {
        val query = """
            SELECT
                c.table_name,
                c.column_name,
                c.data_type,
                c.character_maximum_length,
                c.numeric_precision,
                c.is_nullable,
                c.column_default,
                pg_catalog.col_description((c.table_schema || '.' || c.table_name)::regclass::oid, c.ordinal_position) as column_comment,
                CASE
                    WHEN pk.column_name IS NOT NULL THEN 'YES'
                    ELSE 'NO'
                END as is_primary_key
            FROM information_schema.columns c
            LEFT JOIN (
                SELECT ku.table_name, ku.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage ku
                    ON tc.constraint_name = ku.constraint_name
                    AND tc.table_schema = ku.table_schema
                WHERE tc.constraint_type = 'PRIMARY KEY'
                AND tc.table_schema = 'schmain'
            ) pk ON c.table_name = pk.table_name AND c.column_name = pk.column_name
            WHERE c.table_schema = 'schmain'
            ORDER BY c.table_name, c.ordinal_position
        """.trimIndent()

        return databaseClient.sql(query)
            .map { row, _ ->
                ColumnInfo(
                    tableName = row.get("table_name", String::class.java) ?: "",
                    columnName = row.get("column_name", String::class.java) ?: "",
                    dataType = row.get("data_type", String::class.java) ?: "",
                    maxLength = row.get("character_maximum_length", Integer::class.java)?.toInt(),
                    numericPrecision = row.get("numeric_precision", Integer::class.java)?.toInt(),
                    isNullable = row.get("is_nullable", String::class.java) == "YES",
                    defaultValue = row.get("column_default", String::class.java),
                    comment = row.get("column_comment", String::class.java),
                    isPrimaryKey = row.get("is_primary_key", String::class.java) == "YES"
                )
            }
            .all()
            .collectList()
    }

    /**
     * Obtiene la lista de claves foráneas en el esquema 'schmain'
     */
    fun getForeignKeysInfo(): Mono<List<ForeignKeyInfo>> {
        val query = """
            SELECT
                tc.table_name,
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'schmain'
            ORDER BY tc.table_name, kcu.column_name
        """.trimIndent()

        return databaseClient.sql(query)
            .map { row, _ ->
                ForeignKeyInfo(
                    tableName = row.get("table_name", String::class.java) ?: "",
                    columnName = row.get("column_name", String::class.java) ?: "",
                    foreignTableName = row.get("foreign_table_name", String::class.java) ?: "",
                    foreignColumnName = row.get("foreign_column_name", String::class.java) ?: ""
                )
            }
            .all()
            .collectList()
    }

    /**
     * Analiza el mensaje de error de PostgreSQL para proporcionar feedback útil
     */
    private fun analyzePostgresError(errorMessage: String): Pair<ErrorType, String> {
        val lowerError = errorMessage.lowercase()

        return when {
            lowerError.contains("relation") && lowerError.contains("does not exist") -> {
                ErrorType.TABLE_NOT_FOUND to "La tabla especificada no existe. Verifica el nombre y usa 'schmain.' como prefijo"
            }

            lowerError.contains("column") && lowerError.contains("does not exist") -> {
                ErrorType.COLUMN_NOT_FOUND to "La columna especificada no existe en la tabla. Verifica el nombre de la columna"
            }

            lowerError.contains("syntax error") -> {
                ErrorType.SYNTAX_ERROR to "Error de sintaxis SQL. Verifica la estructura del query"
            }

            lowerError.contains("aggregate") -> {
                ErrorType.AGGREGATE_ERROR to "Error en función de agregación. Verifica que todas las columnas no agregadas estén en GROUP BY"
            }

            lowerError.contains("group by") -> {
                ErrorType.GROUP_BY_ERROR to "Error en GROUP BY. Incluye todas las columnas no agregadas en la cláusula GROUP BY"
            }

            lowerError.contains("join") -> {
                ErrorType.JOIN_ERROR to "Error en JOIN. Verifica las condiciones ON y que las columnas existan en ambas tablas"
            }

            lowerError.contains("ambiguous") -> {
                ErrorType.AMBIGUOUS_COLUMN to "Columna ambigua. Usa alias de tabla (ej: p.name) para especificar de qué tabla es la columna"
            }

            lowerError.contains("type") && lowerError.contains("mismatch") -> {
                ErrorType.TYPE_MISMATCH to "Error de tipo de datos. Verifica que los tipos sean compatibles en comparaciones"
            }

            else -> {
                ErrorType.UNKNOWN_ERROR to "Error SQL: $errorMessage"
            }
        }
    }

    /**
     * Formatea los resultados de la query en un string legible
     **/
    private fun formatQueryResults(results: List<Map<String, Any>>, query: String): String {
        return if (results.isEmpty()) {
            "No se encontraron resultados para tu consulta."
        } else {
            val sb = StringBuilder()

            // Determinar el tipo de consulta basado en el contenido
            when {
                query.contains("COUNT(*)") && query.contains("SUM(stock_quantity)") -> {
                    // Resumen de stock
                    val result = results.first()
                    sb.append("📊 **Resumen de Inventario:**\n\n")
                    sb.append("• Total de productos: ${result["total_products"]}\n")
                    sb.append("• Stock total: ${result["total_stock"]} unidades\n")
                    sb.append("• Productos con stock bajo: ${result["low_stock_products"]}\n")
                    if (result.containsKey("out_of_stock_products")) {
                        sb.append("• Productos sin stock: ${result["out_of_stock_products"]}\n")
                    }
                    if (result.containsKey("expiring_products")) {
                        sb.append("• Productos por vencer (30 días): ${result["expiring_products"]}\n")
                    }
                }

                query.contains("product_id =") && query.contains("stock_quantity") -> {
                    // Consulta específica de producto
                    val result = results.first()
                    sb.append("📦 **Información del Producto:**\n\n")
                    sb.append("• Nombre: ${result["name"]}\n")
                    sb.append("• Stock actual: ${result["stock_quantity"]} unidades\n")
                    sb.append("• Stock mínimo: ${result["stock_minimum"]} unidades\n")
                    sb.append("• Precio: $${result["price"]}\n")
                    sb.append("• Categoría: ${result["category_name"]}\n")
                    sb.append("• Estado: ${result["stock_status"]}\n")
                }

                query.contains("total_sold") && query.contains("total_revenue") -> {
                    // Productos más vendidos
                    sb.append("🏆 **Productos Más Vendidos:**\n\n")
                    results.forEachIndexed { index, result ->
                        sb.append("${index + 1}. **${result["name"]}**\n")
                        sb.append("   • Unidades vendidas: ${result["total_sold"]}\n")
                        sb.append("   • Ingresos totales: $${result["total_revenue"]}\n")
                        sb.append("   • Categoría: ${result["category_name"]}\n\n")
                    }
                }

                query.contains("stock_quantity") && query.contains("stock_minimum") -> {
                    // Productos con stock bajo
                    sb.append("⚠️ **Productos con Stock Bajo:**\n\n")
                    results.forEachIndexed { index, result ->
                        sb.append("${index + 1}. **${result["name"]}**\n")
                        sb.append("   • Stock actual: ${result["stock_quantity"]} unidades\n")
                        sb.append("   • Stock mínimo: ${result["stock_minimum"]} unidades\n")
                        sb.append("   • Categoría: ${result["category_name"]}\n\n")
                    }
                }

                query.contains("sale_id") && query.contains("total_amount") -> {
                    // Ventas recientes
                    sb.append("💰 **Ventas Recientes:**\n\n")
                    results.forEachIndexed { index, result ->
                        sb.append("${index + 1}. Venta #${result["sale_id"]}\n")
                        sb.append("   • Cliente: ${result["person_name"] ?: "Sin cliente"}\n")
                        sb.append("   • Monto: $${result["total_amount"]}\n")
                        sb.append("   • Fecha: ${result["sale_date"]}\n")
                        sb.append("   • Método de pago: ${result["pay_method"]}\n\n")
                    }
                }

                else -> {
                    // Formato genérico
                    sb.append("Encontré ${results.size} resultado(s):\n\n")
                    results.forEachIndexed { index, result ->
                        sb.append("${index + 1}. ")
                        result.forEach { (key, value) ->
                            sb.append("$key: $value, ")
                        }
                        sb.append("\n")
                    }
                }
            }

            sb.toString()
        }
    }
}