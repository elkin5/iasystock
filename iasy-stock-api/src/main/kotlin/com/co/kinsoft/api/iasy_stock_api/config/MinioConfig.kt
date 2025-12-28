package com.co.kinsoft.api.iasy_stock_api.config

import io.minio.MinioClient
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.stereotype.Component

@Configuration
@EnableConfigurationProperties(MinioProperties::class)
class MinioConfig(private val minioProperties: MinioProperties) {

    @Bean
    fun minioClient(): MinioClient {
        return MinioClient.builder()
            .endpoint(minioProperties.endpoint)
            .credentials(minioProperties.accessKey, minioProperties.secretKey)
            .region(minioProperties.region)
            .build()
    }
}

@Component
@ConfigurationProperties(prefix = "minio")
data class MinioProperties(
    var endpoint: String = "",
    var accessKey: String = "",
    var secretKey: String = "",
    var region: String = "",
    var apiBaseUrl: String = "http://localhost:8089",
    var bucket: BucketProperties = BucketProperties(),
    var security: SecurityProperties = SecurityProperties()
) {
    data class BucketProperties(
        var productImages: String = "product-images"
    )
    
    data class SecurityProperties(
        var usePresignedUrls: Boolean = true,
        var defaultExpiryHours: Long = 24,
        var maxExpiryHours: Long = 168,
        var maxFileSizeMb: Long = 10,
        var allowedContentTypes: List<String> = listOf("image/jpeg", "image/jpg", "image/png", "image/webp")
    )
}
