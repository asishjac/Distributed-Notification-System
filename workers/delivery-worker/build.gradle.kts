plugins {
    kotlin("jvm") version "2.2.21"
    id("com.gradleup.shadow") version "8.3.3"
}

group = "com.showcase.notification.worker"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    // AWS Lambda Core and Events
    implementation("com.amazonaws:aws-lambda-java-core:1.2.3")
    implementation("com.amazonaws:aws-lambda-java-events:3.11.4")

    // AWS Kotlin SDK for DynamoDB
    implementation("aws.sdk.kotlin:dynamodb:1.0.35")

    // JSON Parsing (Jackson Kotlin)
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin:2.16.1")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    // Logging
    implementation("org.slf4j:slf4j-simple:2.0.12")

    // Testing
    testImplementation(kotlin("test"))
    testImplementation("io.mockk:mockk:1.13.9")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
}

tasks.test {
    useJUnitPlatform()
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

// Ensure shadowJar outputs properly for AWS Lambda (Uber JAR)
tasks.withType<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar> {
    archiveClassifier.set("")
    archiveVersion.set("")
    mergeServiceFiles()
}
