#!/bin/bash
cd notification-gateway
echo "1. Building and starting Spring Boot Application..."
./gradlew bootRun > app.log 2>&1 &
APP_PID=$!

echo "Waiting for Spring Boot to fully initialize (checking logs)..."
while ! grep -q "Started NotificationGatewayApplication" app.log; do
    if grep -q "FAILED" app.log || grep -q "Error starting ApplicationContext" app.log; then
        echo "Spring Boot failed to start!"
        cat app.log
        kill -9 $APP_PID
        exit 1
    fi
    sleep 2
    printf "."
done
echo -e "\nServer successfully stated!"

echo "2. Populating PostgreSQL Database..."
docker exec shared_postgres psql -U admin -d notification_db -c "INSERT INTO user_preferences (id, user_id, email_enabled, sms_enabled) VALUES ('123e4567-e89b-12d3-a456-426614174000', 'user123', true, true) ON CONFLICT DO NOTHING;"

echo "3. Invoking the Notification API..."
CMD_OUT=$(curl -s -X POST http://localhost:8081/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: docker-integration-1" \
  -d '{"userId": "user123", "message": "Docker test message!"}')
echo "Gateway API Response: $CMD_OUT"

echo "4. Giving Coroutines 2 seconds to process asynchronous AWS calls..."
sleep 2

echo "5. Polling AWS LocalStack SQS..."
docker exec shared_localstack awslocal sqs receive-message --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/notification-queue

echo "Shutting down Spring Boot..."
kill -9 $APP_PID
