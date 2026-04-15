package com.showcase.notification.worker

import aws.sdk.kotlin.services.dynamodb.DynamoDbClient
import aws.sdk.kotlin.services.dynamodb.model.PutItemRequest
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

class DeliveryLogRepositoryTest {

    private val dynamoDbClient = mockk<DynamoDbClient>()
    private val repository = DeliveryLogRepository(dynamoDbClient)

    @Test
    fun `saveDeliveryLog successfully puts item into DynamoDB`() = runTest {
        // Given
        val log = DeliveryLog(
            userId = "user123",
            traceId = "trace-uuid-1",
            correlationId = "corr-uuid-1",
            channel = "EMAIL",
            status = "DELIVERED",
            deliveredAt = "2023-10-27T10:00:00Z"
        )
        val requestSlot = slot<PutItemRequest>()
        coEvery { dynamoDbClient.putItem(capture(requestSlot)) } returns mockk()

        // When
        repository.saveDeliveryLog(log)

        // Then
        coVerify(exactly = 1) { dynamoDbClient.putItem(any()) }
        val capturedRequest = requestSlot.captured
        assertEquals("NotificationDeliveryLogs", capturedRequest.tableName)
        assertEquals("user123", capturedRequest.item?.get("userId")?.asS())
        assertEquals("trace-uuid-1", capturedRequest.item?.get("traceId")?.asS())
        assertEquals("corr-uuid-1", capturedRequest.item?.get("correlationId")?.asS())
        assertEquals("EMAIL", capturedRequest.item?.get("channel")?.asS())
        assertEquals("DELIVERED", capturedRequest.item?.get("status")?.asS())
        assertEquals("2023-10-27T10:00:00Z", capturedRequest.item?.get("deliveredAt")?.asS())
    }

    @Test
    fun `saveDeliveryLog throws exception when DynamoDB putItem fails`() = runTest {
        // Given
        val log = DeliveryLog("u", "t", "c", "E", "D", "now")
        coEvery { dynamoDbClient.putItem(any()) } throws RuntimeException("DynamoDB Error")

        // When/Then
        assertThrows<RuntimeException> {
            repository.saveDeliveryLog(log)
        }
    }
}
