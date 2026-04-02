package com.showcase.notification.config

import aws.sdk.kotlin.services.sqs.SqsClient
import aws.smithy.kotlin.runtime.net.url.Url
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class AwsConfig(
    @Value("\${aws.region}") private val region: String,
    @Value("\${aws.endpoint:#{null}}") private val endpointOverride: String?
) {

    // Using the official Native Kotlin AWS SDK client instance
    @Bean
    fun sqsClient(): SqsClient {
        return SqsClient {
            region = this@AwsConfig.region
            endpointOverride?.let { url ->
                endpointUrl = Url.parse(url)
            }
        }
    }
}
