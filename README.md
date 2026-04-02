# Distributed Notification System

An event-driven Notification System built to showcase architectural and engineering standards using modern high-performance cloud tools.

## Tech Stack
- **Kotlin & Spring Boot (Coroutines)**: API layer and logic.
- **AWS SQS & Lambda**: Asynchronous queues and Serverless delivery workers.
- **PostgreSQL**: Relational schema for managing users, preferences, and templates.
- **DynamoDB**: High-velocity NoSQL store for tracking global delivery logs.
- **Terraform**: Complete Infrastructure as Code setup.
- **LocalStack**: Local sandbox for AWS (SQS, Lambda, DynamoDB).

## Directory Structure
- `notification-gateway/`: Core REST API application built on Spring Boot & Kotlin.
- `workers/delivery-worker/`: Pure Kotlin AWS Lambda Serverless worker function.
- `infrastructure/`: Terraform IaC modules and scripts.
- `docs/`: Contribution guidelines and system design documents.

## Local Setup
1. **Environment Configuration**: Because this project enforces strict credential security, you must create a local environment file before starting the infrastructure.
   ```bash
   cp .env.example .env
   ```
   *(Feel free to edit `.env` to set your own passwords. Since it is in `.gitignore`, it will never be committed to Git).*

2. **Start the Infrastructure**: Ensure you have Docker installed and running. Start the entire dependent stack (Database, Mock AWS environment, pgAdmin): 
```bash
docker-compose up -d
```
