package com.showcase.notification.worker

import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.events.SQSEvent
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

class DeliveryWorkerHandlerTest {

    private val repository = mockk<DeliveryLogRepository>()
    private val mapper = jacksonObjectMapper()
    private val handler = DeliveryWorkerHandler(repository, mapper)
    private val context = mockk<Context>(relaxed = true)

    @Test
    fun `handleRequest processes multiple SQS records correctly`() {
        // Given
        val message1 = NotificationMessage("t1", "c1", "u1", "EMAIL", "Hello 1")
        val message2 = NotificationMessage("t2", "c2", "u2", "SMS", "Hello 2")

        val record1 = SQSEvent.SQSMessage().apply {
            body = mapper.writeValueAsString(message1)
            messageId = "msg-1"
        }
        val record2 = SQSEvent.SQSMessage().apply {
            body = mapper.writeValueAsString(message2)
            messageId = "msg-2"
        }

        val event = SQSEvent().apply {
            records = listOf(record1, record2)
        }

        coEvery { repository.saveDeliveryLog(any()) } returns Unit

        // When
        val result = handler.handleRequest(event, context)

        // Then
        assertEquals("Successfully processed 2 records.", result)
        coVerify(exactly = 1) {
            repository.saveDeliveryLog(match { it.traceId == "t1" && it.channel == "EMAIL" })
        }
        coVerify(exactly = 1) {
            repository.saveDeliveryLog(match { it.traceId == "t2" && it.channel == "SMS" })
        }
    }

    @Test
    fun `handleRequest throws exception if record processing fails`() {
        // Given
        val message = NotificationMessage("t", "c", "u", "EMAIL", "Hello")
        val record = SQSEvent.SQSMessage().apply {
            body = mapper.writeValueAsString(message)
            messageId = "msg-1"
        }
        val event = SQSEvent().apply {
            records = listOf(record)
        }

        coEvery { repository.saveDeliveryLog(any()) } throws RuntimeException("Repo Error")

        // When/Then
        assertThrows<RuntimeException> {
            handler.handleRequest(event, context)
        }
    }
}
