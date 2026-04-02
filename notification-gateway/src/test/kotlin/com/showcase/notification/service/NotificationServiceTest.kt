package com.showcase.notification.service

import aws.sdk.kotlin.services.sqs.SqsClient
import aws.sdk.kotlin.services.sqs.model.SendMessageRequest
import aws.sdk.kotlin.services.sqs.model.SendMessageResponse
import com.showcase.notification.domain.UserPreferences
import com.showcase.notification.domain.UserPreferencesRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test
import java.util.UUID

class NotificationServiceTest {

    private val sqsClient = mockk<SqsClient>()
    private val preferencesRepository = mockk<UserPreferencesRepository>()
    private val queueUrl = "http://localhost:4566/mock-queue"

    // Constructing the Service with Mocks
    private val notificationService = NotificationService(sqsClient, preferencesRepository, queueUrl)

    @Test
    fun `should publish SMS and EMAIL to SQS when user has both enabled`() = runTest {
        val userId = "user123"
        val message = "Welcome aboard!"
        
        // Mocking Coroutine Data Repository (coEvery)
        coEvery { preferencesRepository.findByUserId(userId) } returns UserPreferences(
            userId = userId,
            emailEnabled = true,
            smsEnabled = true
        )
        
        // Mocking Coroutine Network Call
        coEvery { sqsClient.sendMessage(any<SendMessageRequest>()) } returns SendMessageResponse {}

        // Execute Suspend Function
        notificationService.sendNotification(userId, message, "mock-correlation-id", "mock-trace-id")

        // Verify that Coroutine was executed exactly twice (Email + SMS)
        coVerify(exactly = 2) { sqsClient.sendMessage(any<SendMessageRequest>()) }
    }

    @Test
    fun `should throw error if user preferences not found`() = runTest {
        val userId = "unknownUser"
        
        // Mock repository returning null
        coEvery { preferencesRepository.findByUserId(userId) } returns null

        // Verify Exception is Thrown in Coroutine Context
        assertThrows(IllegalArgumentException::class.java) {
            runTest {
                notificationService.sendNotification(userId, "Hello", "mock-correlation-id", "mock-trace-id")
            }
        }
        
        // Verify SQS was never called
        coVerify(exactly = 0) { sqsClient.sendMessage(any<SendMessageRequest>()) }
    }
}
