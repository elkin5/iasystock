package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai

import com.fasterxml.jackson.core.JsonParser
import com.fasterxml.jackson.databind.DeserializationContext
import com.fasterxml.jackson.databind.JsonDeserializer
import com.fasterxml.jackson.databind.JsonNode

/**
 * Deserializador que permite recibir cadenas que eventualmente vienen como arreglos.
 * Une los elementos del arreglo separados por espacio para mantener compatibilidad
 * con el modelo que espera un String plano.
 */
class StringOrArrayDeserializer : JsonDeserializer<String>() {

    override fun deserialize(parser: JsonParser, context: DeserializationContext): String {
        val node: JsonNode? = parser.codec.readTree(parser)

        return when {
            node == null || node.isNull -> ""
            node.isTextual -> node.asText()
            node.isArray -> node.filterNotNull().joinToString(" ") { it.asText("") }.trim()
            else -> node.asText()
        }
    }

    override fun getNullValue(ctxt: DeserializationContext?): String = ""
}
