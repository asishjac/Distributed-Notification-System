package com.showcase.notification.worker

import com.fasterxml.jackson.annotation.JsonProperty

/**
 * Represents the JSON payload we expect to receive inside the body of an SQSEvent.
 * This exactly matches the Payload the Gateway sends up containing the Trace ID and localized message.
 */
data class NotificationMessage(
    @JsonProperty("traceId") val traceId: String,
    @JsonProperty("correlationId") val correlationId: String,
    @JsonProperty("userId") val userId: String,
    @JsonProperty("channel") val channel: String,
    @JsonProperty("content") val content: String
)
