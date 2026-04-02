package com.showcase.notification.utils

import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * By using an inline reified generic, we can determine the exact class type at runtime.
 * Usage: log().info("Message")
 */
inline fun <reified T> T.log(): Logger = LoggerFactory.getLogger(T::class.java)
