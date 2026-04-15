package com.showcase.notification.worker

import java.time.Instant

/**
 * Represents the log that will be written to DynamoDB upon successful or failed third-party delivery.
 */
data class DeliveryLog(
    val userId: String,          // DynamoDB Partition Key (PK)
    val traceId: String,         // DynamoDB Sort Key (SK)
    val correlationId: String,   // To tie it back to the original caller
    val channel: String,
    val status: String,          // "DELIVERED", "FAILED", etc.
    val deliveredAt: String = Instant.now().toString()
)
