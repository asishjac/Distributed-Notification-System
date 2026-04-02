package com.showcase.notification.domain

import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Table
import org.springframework.data.repository.kotlin.CoroutineCrudRepository
import java.time.LocalDateTime
import java.util.UUID

@Table("user_preferences")
data class UserPreferences(
    @Id val id: UUID? = null,
    val userId: String,
    val emailEnabled: Boolean = true,
    val smsEnabled: Boolean = false,
    val pushEnabled: Boolean = true,
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

interface UserPreferencesRepository : CoroutineCrudRepository<UserPreferences, UUID> {
    // Built-in Coroutine support! Calling this behaves like a suspend function
    suspend fun findByUserId(userId: String): UserPreferences?
}
