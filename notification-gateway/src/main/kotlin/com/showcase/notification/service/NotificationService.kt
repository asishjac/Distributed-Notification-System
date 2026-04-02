package com.showcase.notification.service

import aws.sdk.kotlin.services.sqs.SqsClient
import aws.sdk.kotlin.services.sqs.model.SendMessageRequest
import com.showcase.notification.domain.UserPreferencesRepository
import com.showcase.notification.utils.log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class NotificationService(
    private val sqsClient: SqsClient,
    private val preferencesRepository: UserPreferencesRepository,
    @Value("\${aws.sqs.queue-url}") private val queueUrl: String
) {

    /**
     * Suspend function leveraging Kotlin Coroutines!
     * 1. Fetches user preferences from PostgreSQL asynchronously.
     * 2. If they have the channel enabled, dispatches it to Amazon SQS.
     */
    suspend fun sendNotification(userId: String, message: String, correlationId: String, traceId: String) = withContext(Dispatchers.IO) {
        log().info("Processing notification request for user [{}], traceId: [{}], correlationId: [{}]", userId, traceId, correlationId)

        // Asynchronous DB Call
        val preferences = preferencesRepository.findByUserId(userId) 
            ?: run {
                log().error("User preferences not found for user [{}], traceId: [{}]", userId, traceId)
                throw IllegalArgumentException("User preferences not found for user: \$userId")
            }

        log().debug("Found preferences for user [{}]: email={}, sms={}", userId, preferences.emailEnabled, preferences.smsEnabled)

        if (preferences.emailEnabled) {
            publishToSqs("EMAIL", userId, message, correlationId, traceId)
        }
        
        if (preferences.smsEnabled) {
            publishToSqs("SMS", userId, message, correlationId, traceId)
        }
        
        log().info("Finished processing notification routing for traceId: [{}]", traceId)
    }

    private suspend fun publishToSqs(channel: String, userId: String, message: String, correlationId: String, traceId: String) {
        val payload = """
            {
                "channel": "$channel",
                "userId": "$userId",
                "content": "$message",
                "correlationId": "$correlationId",
                "traceId": "$traceId"
            }
        """.trimIndent()
        
        log().debug("Publishing to SQS for channel [{}] with traceId [{}]", channel, traceId)

        val request = SendMessageRequest {
            queueUrl = this@NotificationService.queueUrl
            messageBody = payload
        }
        
        // Asynchronous Network Call to AWS completely non-blocking
        sqsClient.sendMessage(request)
    }
}
