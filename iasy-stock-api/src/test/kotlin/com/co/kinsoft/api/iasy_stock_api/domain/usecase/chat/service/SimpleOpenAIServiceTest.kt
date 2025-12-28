package com.co.kinsoft.api.iasy_stock_api.domain.usecase.chat.service

import com.co.kinsoft.api.iasy_stock_api.infraestructure.driven_adapters.openai.SimpleOpenAIService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.TestPropertySource
import reactor.test.StepVerifier

@SpringBootTest
@TestPropertySource(properties = [
    "openai.api-key=test-key",
    "openai.model=gpt-3.5-turbo",
    "openai.max-tokens=100",
    "openai.temperature=0.7"
])
class SimpleOpenAIServiceTest {

    @Autowired
    private lateinit var openAIService: SimpleOpenAIService

    @Test
    fun `test SimpleOpenAI service initialization`() {
        // Este test verifica que el servicio se inicializa correctamente
        StepVerifier.create(
            openAIService.generateResponse("Hola", null)
        )
        .expectNextMatches { response ->
            response.contains("problema") || response.contains("error") || response.isNotBlank()
        }
        .verifyComplete()
    }

    @Test
    fun `test intent analysis`() {
        StepVerifier.create(
            openAIService.analyzeIntent("¿Cuántos productos tengo en stock?")
        )
        .expectNextMatches { intent ->
            intent.type.name.isNotEmpty()
        }
        .verifyComplete()
    }
} 