# Contribution Guide

Welcome to the team! We are building the Distributed Notification System. We value clean code, unit testing, and automation.

## Workflow 
1. **Branch Naming**: To contribute code, start by checking out a branch:
    - `feature/name-of-feature`
    - `bugfix/issue-description`
2. **Writing Code**:
    - For Kotlin files, prioritize immutable structures (`val` over `var` and `List` over `MutableList`).
    - Use `suspend` Coroutines anywhere that network I/O or database access occurs.
3. **Run your tests**:
    Ensure code passes the JUnit test suite via `./gradlew test`.
4. **Commits**:
    We follow standard Conventional Commits conventions (e.g. `feat: add email worker`, `fix: sqs payload parse error`).

## What you can work on right now:
Once I have provisioned the basic scaffolding, you can:
- Define new REST routes in `notification-gateway`
- Add tests for corner-cases
- Enhance the DynamoDB table definitions in `infrastructure`
