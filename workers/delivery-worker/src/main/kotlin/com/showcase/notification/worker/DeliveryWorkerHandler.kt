package com.showcase.notification.worker

import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.RequestHandler
import com.amazonaws.services.lambda.runtime.events.SQSEvent
import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory

class DeliveryWorkerHandler(
    private val repository: DeliveryLogRepository,
    private val mapper: com.fasterxml.jackson.databind.ObjectMapper
) : RequestHandler<SQSEvent, String> {

    private val logger = LoggerFactory.getLogger(DeliveryWorkerHandler::class.java)

    constructor() : this(
        repository = DeliveryLogRepository(),
        mapper = jacksonObjectMapper().apply {
            configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
        }
    )

    /**
     * Entry point for AWS Lambda when triggered by SQS.
     */
    override fun handleRequest(event: SQSEvent, context: Context): String {
        logger.info("Lambda invoked with ${event.records.size} SQS Records. RequestId: ${context.awsRequestId}")

        // Launch a Coroutine context to process the batch concurrently
        runBlocking(Dispatchers.IO) {
            val jobs = event.records.map { record ->
                async {
                    processRecord(record)
                }
            }
            jobs.awaitAll()
        }

        return "Successfully processed ${event.records.size} records."
    }

    private suspend fun processRecord(record: SQSEvent.SQSMessage) {
        val payloadBody = record.body
        logger.info("Processing SQS Message ID: ${record.messageId}")

        try {
            val message: NotificationMessage = mapper.readValue(payloadBody)

            logger.info("Simulating delivery via 3rd party for traceId: ${message.traceId} on channel: ${message.channel}")
            
            // Simulate 3rd Party Latency (SendGrid / Twilio)
            kotlinx.coroutines.delay((100..300).random().toLong())

            val finalLog = DeliveryLog(
                userId = message.userId,
                traceId = message.traceId,
                correlationId = message.correlationId,
                channel = message.channel,
                status = "DELIVERED"
            )

            // Asynchronously log to DynamoDB
            repository.saveDeliveryLog(finalLog)

        } catch (ex: Exception) {
            logger.error("Failed to parse or process record ID: ${record.messageId}. Payload: $payloadBody", ex)
            // Note: If you want to force SQS retries, you would throw the exception here.
            // Throwing ex causes the Lambda to fail, leaving the message in the queue/DLQ.
            throw ex 
        }
    }
}
