package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat

import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.r2dbc_postgresql.chat.ChatMessage
import reactor.core.publisher.Mono

class PromptBuilderUseCase(
    private val databaseSchemaUseCase: DatabaseSchemaUseCase,
    private val chatKnowledgeUseCase: ChatKnowledgeUseCase
) {

    fun buildPrompt(
        userMessage: String,
        intent: UserIntent,
        databaseData: String? = null,
        conversationHistory: List<ChatMessage> = emptyList(),
        similarQueries: List<SimilarQuery> = emptyList()
    ): Mono<String> {
        // OPTIMIZACIÓN: Usar StringBuilder para evitar múltiples strings intermedios
        val promptBuilder = StringBuilder()

        promptBuilder.append(buildBasePrompt(intent))
        promptBuilder.append("\n\n")
        promptBuilder.append(buildNaturalLanguageInstructions())
        promptBuilder.append("\n\n")
        promptBuilder.append(chatKnowledgeUseCase.formatSimilarQueriesAsExamples(similarQueries))
        promptBuilder.append("\n\n")
        promptBuilder.append(buildHistoryPrompt(conversationHistory))
        promptBuilder.append("\n\n")
        promptBuilder.append(buildDataPrompt(databaseData))
        promptBuilder.append("\n\nPregunta del usuario: ")
        promptBuilder.append(userMessage)
        promptBuilder.append("\n\nPor favor, responde de manera clara, concisa y útil basándote EXCLUSIVAMENTE en los datos reales proporcionados.")

        return Mono.just(promptBuilder.toString())
    }

    private fun buildBasePrompt(intent: UserIntent): String {
        return when (intent.type) {
            IntentType.STOCK_QUERY -> """
                Eres un asistente especializado en consultas de inventario y stock.
                Tu función es ayudar a los usuarios a entender el estado de su inventario.
                
                REGLAS IMPORTANTES:
                - SIEMPRE usa los datos reales proporcionados para responder
                - Si tienes datos específicos, úsalos directamente
                - NO sugieras consultar la base de datos si ya tienes los datos
                - Proporciona respuestas precisas basadas en los datos disponibles
                
                Puedes consultar información sobre:
                - Cantidad de productos en stock
                - Productos con stock bajo
                - Productos por agotarse
                - Valor total del inventario
                - Productos por vencer
            """.trimIndent()

            IntentType.SALES_QUERY -> """
                Eres un asistente especializado en consultas de ventas y reportes comerciales.
                Tu función es ayudar a los usuarios a analizar sus ventas.
                
                REGLAS IMPORTANTES:
                - SIEMPRE usa los datos reales proporcionados para responder
                - Si tienes datos específicos, úsalos directamente
                - NO sugieras consultar la base de datos si ya tienes los datos
                - Proporciona respuestas precisas basadas en los datos disponibles
                
                Puedes consultar información sobre:
                - Ventas recientes
                - Productos más vendidos
                - Mejores clientes
                - Tendencias de ventas
                - Métodos de pago utilizados
            """.trimIndent()

            IntentType.PRODUCT_QUERY -> """
                Eres un asistente especializado en consultas de productos.
                Tu función es ayudar a los usuarios a encontrar información sobre productos.
                
                REGLAS IMPORTANTES:
                - SIEMPRE usa los datos reales proporcionados para responder
                - Si tienes datos específicos, úsalos directamente
                - NO sugieras consultar la base de datos si ya tienes los datos
                - Proporciona respuestas precisas basadas en los datos disponibles
                
                Puedes consultar información sobre:
                - Productos disponibles
                - Categorías de productos
                - Precios y descripciones
                - Productos por categoría
                - Detalles específicos de productos
            """.trimIndent()

            IntentType.GENERAL_QUERY -> """
                Eres un asistente inteligente para el sistema de gestión de inventarios IasyStock.
                Tu función es ayudar a los usuarios con cualquier consulta relacionada con el sistema.
                
                REGLAS IMPORTANTES:
                - SIEMPRE usa los datos reales proporcionados para responder
                - Si tienes datos específicos, úsalos directamente
                - NO sugieras consultar la base de datos si ya tienes los datos
                - Proporciona respuestas precisas basadas en los datos disponibles
                
                Puedes ayudar con:
                - Consultas generales sobre el sistema
                - Información sobre funcionalidades
                - Guías de uso
                - Resolución de dudas
            """.trimIndent()
        }
    }

    private fun buildHistoryPrompt(conversationHistory: List<ChatMessage>): String {
        return if (conversationHistory.isNotEmpty()) {
            val historyText = StringBuilder()
            historyText.append("HISTORIAL DE LA CONVERSACIÓN:\n\n")

            conversationHistory.forEach { message ->
                val role = if (message.role == "user") "Usuario" else "Asistente"
                historyText.append("$role: ${message.content}\n")
            }

            historyText.append("\n")
            historyText.append(
                """
                INSTRUCCIONES PARA USO DEL HISTORIAL:
                - Usa el historial para entender el contexto de la conversación actual
                - Si el usuario hace referencia a algo mencionado anteriormente (ej: "¿y del producto 3?", "¿cuántos hay?"), usa el historial para inferir el contexto
                - Mantén coherencia con las respuestas anteriores
                - Si el usuario pregunta algo relacionado con una consulta previa, puedes hacer referencia a ella
                - NO repitas información ya proporcionada a menos que el usuario lo solicite explícitamente
            """.trimIndent()
            )

            historyText.toString()
        } else {
            """
            HISTORIAL DE LA CONVERSACIÓN:
            Esta es la primera interacción de la conversación.
            """.trimIndent()
        }
    }

    private fun buildDataPrompt(databaseData: String?): String {
        return if (databaseData != null && databaseData.isNotBlank()) {
            """
            DATOS REALES DE LA BASE DE DATOS:
            $databaseData

            INSTRUCCIONES IMPORTANTES:
            1. Los datos anteriores son REALES y actuales de la base de datos
            2. SIEMPRE usa estos datos para responder la pregunta del usuario
            3. Si los datos contienen la información solicitada, proporciona la respuesta específica
            4. Si los datos no contienen la información solicitada, indícalo claramente
            5. NO sugieras consultar la base de datos si ya tienes los datos

            EJEMPLO: Si el usuario pregunta "¿Cuántos productos tengo en stock para el producto 5?" y los datos muestran "Stock actual: 30 unidades", responde "El producto 5 tiene 30 unidades en stock."
            """.trimIndent()
        } else {
            """
            No se obtuvieron datos específicos de la base de datos para esta consulta.
            Responde de manera general o sugiere qué información adicional podría ser útil.
            """.trimIndent()
        }
    }

    private fun buildNaturalLanguageInstructions(): String {
        return """
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            INSTRUCCIONES PARA RESPONDER EN LENGUAJE NATURAL
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            TU OBJETIVO: Convertir datos técnicos de base de datos en respuestas amigables en español.

            ❌ NUNCA HAGAS:
            - Mostrar código SQL en la respuesta
            - Sugerir al usuario que ejecute consultas
            - Explicar cómo obtuviste los datos
            - Mencionar términos técnicos como "base de datos", "query", "tabla", "JOIN"
            - Responder sin usar los datos reales proporcionados

            ✅ SIEMPRE HAZLO ASÍ:
            1. Lee los DATOS REALES proporcionados arriba
            2. Extrae la información relevante para responder la pregunta
            3. Presenta los datos de forma conversacional y amigable
            4. Usa emojis ocasionales para hacer la respuesta más visual (📊 💰 📦 ⚠️ ✅)
            5. Formatea números con separadores de miles (ej: $3,380,000 en lugar de 3380000)
            6. Formatea fechas en español (ej: "21 de octubre de 2025" en lugar de "2025-10-21")
            7. Si hay múltiples resultados, usa listas numeradas o bullets
            8. Si NO hay resultados, explícalo amigablemente y sugiere alternativas

            EJEMPLOS DE CÓMO RESPONDER:

            Ejemplo 1 - Listado de ventas pendientes:
            Usuario: "¿Puedes hacer un listado de las ventas pendientes?"
            Datos: sale_id=10, total=3380000, fecha=2025-10-21, cliente="Juan Pérez"
                   sale_id=11, total=3380000, fecha=2025-10-23, cliente="María López"

            ✅ RESPUESTA CORRECTA:
            "Encontré 2 ventas pendientes:

            1. 📋 Venta #10 - $3,380,000
               • Cliente: Juan Pérez
               • Fecha: 21 de octubre de 2025
               • Método de pago: Efectivo

            2. 📋 Venta #11 - $3,380,000
               • Cliente: María López
               • Fecha: 23 de octubre de 2025
               • Método de pago: No especificado

            Ambas ventas están pendientes de completar."

            ❌ RESPUESTA INCORRECTA:
            "Para obtener las ventas pendientes, ejecuté: SELECT * FROM sale WHERE state = 'Pendiente'..."

            Ejemplo 2 - Sin resultados:
            Usuario: "¿Qué productos están vencidos?"
            Datos: (vacío)

            ✅ RESPUESTA CORRECTA:
            "¡Buenas noticias! 🎉 No hay productos vencidos en este momento.

            ¿Te gustaría ver:
            • Productos próximos a vencer
            • Estado general del inventario
            • Productos con stock bajo?"

            Ejemplo 3 - Datos agregados:
            Usuario: "¿Cuántos productos tengo?"
            Datos: total_productos=45, total_stock=1250, productos_bajo=3

            ✅ RESPUESTA CORRECTA:
            "Actualmente tienes:

            📦 45 productos diferentes
            📊 1,250 unidades en stock total
            ⚠️ 3 productos con stock bajo

            ¿Quieres ver el detalle de los productos con stock bajo?"

            TONO Y ESTILO:
            - Amigable pero profesional
            - Directo y conciso
            - Enfocado en la acción (qué puede hacer el usuario ahora)
            - Proactivo en ofrecer información relacionada útil
            """.trimIndent()
    }
}