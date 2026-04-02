package com.showcase.notification.web

import com.showcase.notification.service.NotificationService
import com.showcase.notification.utils.log
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1/notifications")
class NotificationController(
    private val notificationService: NotificationService
) {

    data class NotificationRequest(
        val userId: String,
        val message: String
    )

    data class NotificationResponse(
        val status: String,
        val trackingId: String
    )

    @PostMapping
    suspend fun triggerNotification(
        @RequestHeader("X-Correlation-ID", required = false) correlationIdHeader: String?,
        @RequestBody request: NotificationRequest
    ): ResponseEntity<NotificationResponse> {
        
        // The correlationId allows the caller to trace their request (defaulting to a new UUID if they didn't provide one).
        val correlationId = correlationIdHeader ?: UUID.randomUUID().toString()
        
        // The traceId is guaranteed to be universally unique for our internal system, regardless of what the caller sent.
        val traceId = UUID.randomUUID().toString()
        
        log().info("Received notification request for user [{}]. correlationId: [{}], internalTraceId: [{}]", request.userId, correlationId, traceId)

        notificationService.sendNotification(request.userId, request.message, correlationId, traceId)
        
        log().info("Successfully enqueued notification. internalTraceId: [{}]", traceId)
        return ResponseEntity.accepted().body(
            NotificationResponse("ACCEPTED", traceId)
        )
    }
}
