package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatRepository
import org.slf4j.LoggerFactory
import reactor.core.publisher.Mono

class DatabaseSchemaUseCase(
    private val chatRepository: ChatRepository
) {

    private val logger = LoggerFactory.getLogger(DatabaseSchemaUseCase::class.java)

    // Cache del esquema para evitar consultas repetidas
    @Volatile
    private var cachedSchema: String? = null

    /**
     * Obtiene el esquema completo de la base de datos en formato optimizado para LLM
     */
    fun getCompleteSchema(): Mono<String> {
        // Si ya está en caché, retornar inmediatamente
        cachedSchema?.let {
            logger.debug("Retornando esquema desde caché")
            return Mono.just(it)
        }

        return buildSchemaDescription()
            .doOnSuccess { schema ->
                cachedSchema = schema
                logger.info("Esquema de BD cargado y cacheado exitosamente")
            }
            .doOnError { error ->
                logger.error("Error obteniendo esquema de BD", error)
            }
    }

    /**
     * Invalida el caché del esquema (útil si la estructura de BD cambia)
     */
    fun invalidateCache() {
        cachedSchema = null
        logger.info("Caché del esquema invalidado")
    }

    private fun buildSchemaDescription(): Mono<String> {
        return Mono.zip(
            chatRepository.getTablesInfo(),
            chatRepository.getColumnsInfo(),
            chatRepository.getForeignKeysInfo()
        ).map { tuple ->
            val tables = tuple.t1
            val columns = tuple.t2
            val foreignKeys = tuple.t3

            formatSchemaForLLM(tables, columns, foreignKeys)
        }
    }

    private fun formatSchemaForLLM(
        tables: List<TableInfo>,
        columns: List<ColumnInfo>,
        foreignKeys: List<ForeignKeyInfo>
    ): String {
        val sb = StringBuilder()

        sb.append("ESQUEMA COMPLETO DE LA BASE DE DATOS (schmain):\n\n")

        // Agrupar columnas por tabla
        val columnsByTable = columns.groupBy { it.tableName }
        val fksByTable = foreignKeys.groupBy { it.tableName }

        tables.forEach { table ->
            sb.append("TABLA: ${table.name}\n")

            // Descripción de la tabla si existe
            table.comment?.let { comment ->
                sb.append("Descripción: $comment\n")
            }

            // Columnas de la tabla
            val tableColumns = columnsByTable[table.name] ?: emptyList()
            tableColumns.forEach { column ->
                sb.append("  - ${column.columnName} (${formatDataType(column)}")

                // Indicadores especiales
                val indicators = mutableListOf<String>()
                if (column.isPrimaryKey) indicators.add("PK")
                if (!column.isNullable) indicators.add("NOT NULL")
                if (column.defaultValue != null) indicators.add("DEFAULT")

                // Verificar si es FK
                val fk = foreignKeys.find {
                    it.tableName == table.name && it.columnName == column.columnName
                }
                if (fk != null) {
                    indicators.add("FK → ${fk.foreignTableName}.${fk.foreignColumnName}")
                }

                if (indicators.isNotEmpty()) {
                    sb.append(", ${indicators.joinToString(", ")}")
                }

                sb.append(")")

                // Comentario de la columna si existe
                column.comment?.let { comment ->
                    sb.append(" - $comment")
                }

                sb.append("\n")
            }

            sb.append("\n")
        }

        // Sección de relaciones resumidas
        if (foreignKeys.isNotEmpty()) {
            sb.append("RELACIONES (FOREIGN KEYS):\n")
            foreignKeys.forEach { fk ->
                sb.append("  - ${fk.tableName}.${fk.columnName} → ${fk.foreignTableName}.${fk.foreignColumnName}\n")
            }
            sb.append("\n")
        }

        // Notas importantes para el LLM
        sb.append(
            """
            NOTAS IMPORTANTES PARA CONSULTAS SQL:
            - Todas las tablas están en el schema 'schmain', usar siempre: schmain.nombre_tabla
            - Para joins, usar las relaciones FK indicadas arriba
            - Los campos de tipo 'timestamp' se comparan con CURRENT_TIMESTAMP o CURRENT_DATE
            - Para fechas usar formato: DATE 'YYYY-MM-DD' o CURRENT_DATE ± INTERVAL 'N days'
            - Para agregaciones, siempre incluir GROUP BY con las columnas no agregadas
            - Usar LEFT JOIN cuando una relación puede ser NULL
            - Usar COALESCE() para manejar valores NULL en agregaciones
        """.trimIndent()
        )

        return sb.toString()
    }

    private fun formatDataType(column: ColumnInfo): String {
        return when (column.dataType.uppercase()) {
            "CHARACTER VARYING", "VARCHAR" -> {
                if (column.maxLength != null) "VARCHAR(${column.maxLength})" else "VARCHAR"
            }

            "NUMERIC" -> {
                if (column.numericPrecision != null) "NUMERIC(${column.numericPrecision})" else "NUMERIC"
            }

            "BIGINT" -> "BIGINT"
            "INTEGER" -> "INTEGER"
            "TEXT" -> "TEXT"
            "TIMESTAMP WITHOUT TIME ZONE" -> "TIMESTAMP"
            "TIMESTAMP WITH TIME ZONE" -> "TIMESTAMPTZ"
            "DATE" -> "DATE"
            "BOOLEAN" -> "BOOLEAN"
            "BYTEA" -> "BYTEA"
            "JSONB" -> "JSONB"
            "ARRAY" -> "ARRAY"
            "USER-DEFINED" -> "VECTOR" // Para pgvector
            else -> column.dataType.uppercase()
        }
    }
}

data class TableInfo(
    val name: String,
    val comment: String? = null
)

data class ColumnInfo(
    val tableName: String,
    val columnName: String,
    val dataType: String,
    val maxLength: Int? = null,
    val numericPrecision: Int? = null,
    val isNullable: Boolean,
    val defaultValue: String? = null,
    val comment: String? = null,
    val isPrimaryKey: Boolean = false
)

data class ForeignKeyInfo(
    val tableName: String,
    val columnName: String,
    val foreignTableName: String,
    val foreignColumnName: String
)
