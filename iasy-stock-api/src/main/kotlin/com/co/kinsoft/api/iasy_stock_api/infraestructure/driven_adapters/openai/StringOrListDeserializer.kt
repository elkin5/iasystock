package com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai

import com.fasterxml.jackson.core.JsonParser
import com.fasterxml.jackson.databind.DeserializationContext
import com.fasterxml.jackson.databind.JsonDeserializer
import com.fasterxml.jackson.databind.JsonNode

/**
 * Deserializador que permite recibir listas que eventualmente vienen como strings vacíos.
 * Maneja casos donde OpenAI devuelve "" en lugar de [] para campos de lista.
 */
class StringOrListDeserializer : JsonDeserializer<List<String>>() {

    override fun deserialize(parser: JsonParser, context: DeserializationContext): List<String> {
        val node: JsonNode? = parser.codec.readTree(parser)

        return when {
            node == null || node.isNull -> emptyList()
            node.isArray -> {
                node.filterNotNull().mapNotNull { 
                    if (it.isTextual) it.asText().takeIf { text -> text.isNotBlank() } else null 
                }
            }
            node.isTextual -> {
                val text = node.asText()
                if (text.isBlank()) emptyList() else listOf(text)
            }
            else -> emptyList()
        }
    }

    override fun getNullValue(ctxt: DeserializationContext?): List<String> = emptyList()
}
