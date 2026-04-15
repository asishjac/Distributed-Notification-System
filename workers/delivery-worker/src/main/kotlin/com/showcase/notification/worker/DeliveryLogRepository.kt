package com.showcase.notification.worker

import aws.sdk.kotlin.services.dynamodb.DynamoDbClient
import aws.sdk.kotlin.services.dynamodb.model.AttributeValue
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import aws.smithy.kotlin.runtime.net.url.Url
import org.slf4j.LoggerFactory
import java.util.Optional.ofNullable

class DeliveryLogRepository(
    private val dynamoDbClient: DynamoDbClient
) {
    private val logger = LoggerFactory.getLogger(DeliveryLogRepository::class.java)

    constructor() : this(
        DynamoDbClient {
            region = System.getenv("AWS_REGION") ?: "us-east-1"
            val endpointUrlString = System.getenv("AWS_ENDPOINT_URL_DYNAMODB")
                ?: System.getenv("AWS_ENDPOINT_URL")

            if (!endpointUrlString.isNullOrBlank()) {
                endpointUrl = Url.parse(endpointUrlString)
            }
        }
    )

    private val tableName = System.getenv("DYNAMODB_TABLE_NAME") ?: "NotificationDeliveryLogs"

    suspend fun saveDeliveryLog(log: DeliveryLog) {
        val itemValues = mapOf(
            "userId" to AttributeValue.S(log.userId),
            "traceId" to AttributeValue.S(log.traceId),
            "correlationId" to AttributeValue.S(log.correlationId),
            "channel" to AttributeValue.S(log.channel),
            "status" to AttributeValue.S(log.status),
            "deliveredAt" to AttributeValue.S(log.deliveredAt)
        )

        val request = PutItemRequest {
            tableName = this@DeliveryLogRepository.tableName
            item = itemValues
        }

        try {
            dynamoDbClient.putItem(request)
            logger.info("Successfully recorded delivery log to DynamoDB for traceId: ${log.traceId}")
        } catch (ex: Exception) {
            logger.error("Failed to write to DynamoDB for traceId: ${log.traceId}", ex)
            throw ex
        }
    }
}
