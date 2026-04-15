#!/bin/bash

# =============================================================================
#  DISTRIBUTED NOTIFICATION SYSTEM — E2E Verifier
# =============================================================================
# This script validates the full notification flow end-to-end:
#   Client → Gateway (Spring Boot) → SQS → Lambda Worker → DynamoDB
#
# Prerequisites:
#   1. Docker Desktop must be running
#   2. `docker-compose up -d` has already been run (infra + Terraform provisioning)
#   3. The worker Shadow JAR has been built: cd workers/delivery-worker && ./gradlew shadowJar
# =============================================================================

set -e  # Exit immediately on any error

# Configuration
GATEWAY_DIR="notification-gateway"
WORKER_DIR="workers/delivery-worker"
SQS_URL="http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/notification-queue"
GATEWAY_PORT=8081

echo "==========================================="
echo "  DISTRIBUTED NOTIFICATION SYSTEM VERIFIER "
echo "==========================================="

# ---------------------------------------------------------------------------
# Step 1: Verify Infrastructure is Ready (provisioned by Terraform)
# ---------------------------------------------------------------------------
echo ""
echo "[ 1/7 ] Verifying Infrastructure (provisioned by Terraform)..."

echo "  → Checking SQS queue..."
if ! docker exec shared_localstack awslocal sqs get-queue-url --queue-name notification-queue > /dev/null 2>&1; then
    echo "  ✗ SQS queue not found. Did Terraform run successfully?"
    echo "    Check logs with: docker logs terraform_provisioner"
    exit 1
fi
echo "  ✓ SQS queue: notification-queue"

echo "  → Checking DynamoDB table..."
if ! docker exec shared_localstack awslocal dynamodb describe-table --table-name NotificationDeliveryLogs > /dev/null 2>&1; then
    echo "  ✗ DynamoDB table not found. Did Terraform run successfully?"
    echo "    Check logs with: docker logs terraform_provisioner"
    exit 1
fi
echo "  ✓ DynamoDB table: NotificationDeliveryLogs"

# ---------------------------------------------------------------------------
# Step 2: Seed Test Data in PostgreSQL
# ---------------------------------------------------------------------------
echo ""
echo "[ 2/7 ] Seeding PostgreSQL User Preferences..."
docker exec shared_postgres psql -U admin -d notification_db -c \
  "INSERT INTO user_preferences (id, user_id, email_enabled, sms_enabled) \
   VALUES ('123e4567-e89b-12d3-a456-426614174000', 'user123', true, true) \
   ON CONFLICT DO NOTHING;" > /dev/null 2>&1
echo "  ✓ User preferences seeded for user123 (email + SMS enabled)"

# ---------------------------------------------------------------------------
# Step 3: Start the Notification Gateway (Spring Boot)
# ---------------------------------------------------------------------------
echo ""
echo "[ 3/7 ] Starting Notification Gateway..."
cd $GATEWAY_DIR
./gradlew bootRun > app.log 2>&1 &
APP_PID=$!

echo "  → Waiting for Gateway to start..."
ELAPSED=0
while ! grep -q "Started NotificationGatewayApplicationKt" app.log 2>/dev/null; do
    if grep -q "FAILED\|BUILD FAILED\|Error" app.log 2>/dev/null && [ "$ELAPSED" -gt 10 ]; then
        echo "  ✗ Gateway failed to start! See logs: notification-gateway/app.log"
        kill -9 $APP_PID 2>/dev/null
        exit 1
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done
echo "  ✓ Gateway is LIVE on port $GATEWAY_PORT"
cd ..

# ---------------------------------------------------------------------------
# Step 4: Send a Notification Request
# ---------------------------------------------------------------------------
echo ""
TRACE_ID="e2e-verify-$(date +%s)"
echo "[ 4/7 ] Sending Notification Request (correlationId: $TRACE_ID)..."

CURL_OUT=$(curl -s -X POST http://localhost:${GATEWAY_PORT}/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: $TRACE_ID" \
  -d '{"userId": "user123", "message": "E2E Verification Message!"}')

echo "  → Gateway Response: $CURL_OUT"

if [[ $CURL_OUT == *"ACCEPTED"* ]]; then
    echo "  ✓ Notification accepted by Gateway"
else
    echo "  ✗ Gateway did not return ACCEPTED status"
    kill -9 $APP_PID 2>/dev/null
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 5: Verify Message in SQS
# ---------------------------------------------------------------------------
echo ""
echo "[ 5/7 ] Checking SQS for queued messages..."
sleep 2
SQS_MSG=$(docker exec shared_localstack awslocal sqs receive-message \
  --queue-url "$SQS_URL" \
  --visibility-timeout 5 2>/dev/null)

if [[ $SQS_MSG == *"Body"* ]]; then
    echo "  ✓ Message found in SQS queue"
else
    echo "  ✗ SQS queue is empty — Gateway may not have published"
    kill -9 $APP_PID 2>/dev/null
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 6: Run the Delivery Worker (simulated Lambda)
# ---------------------------------------------------------------------------
echo ""
echo "[ 6/7 ] Running Delivery Worker (Shadow JAR)..."
cd $WORKER_DIR

if [ ! -f "build/libs/delivery-worker.jar" ]; then
    echo "  → Shadow JAR not found, building now..."
    ./gradlew shadowJar > /dev/null 2>&1
fi

# Load env vars from project root .env file
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ENDPOINT_URL_DYNAMODB=http://localhost:4566
export DYNAMODB_TABLE_NAME=NotificationDeliveryLogs

java -jar build/libs/delivery-worker.jar > worker.log 2>&1 &
WORKER_PID=$!
sleep 8  # Allow worker time to consume from SQS and write to DynamoDB
cd ../..

# ---------------------------------------------------------------------------
# Step 7: Verify Delivery Log in DynamoDB
# ---------------------------------------------------------------------------
echo ""
echo "[ 7/7 ] Verifying Delivery Log in DynamoDB..."
DYNAMO_OUT=$(docker exec shared_localstack awslocal dynamodb scan \
  --table-name NotificationDeliveryLogs)

if [[ $DYNAMO_OUT == *"DELIVERED"* ]]; then
    echo "  ✓ Delivery log found with status=DELIVERED"
    echo ""
    echo "==========================================="
    echo "  ✅  FULL INTEGRATION TEST: SUCCESS       "
    echo "==========================================="
    echo ""
    echo "  Trace the lifecycle:"
    echo "  • PostgreSQL:  user preferences checked ✓"
    echo "  • SQS:         message published ✓"
    echo "  • Worker:      message consumed and processed ✓"
    echo "  • DynamoDB:    delivery receipt written ✓"
    echo ""
    echo "  View records at: http://localhost:8001"
else
    echo "  ✗ No DELIVERED record found in DynamoDB"
    echo "  DynamoDB scan output: $DYNAMO_OUT"
    echo ""
    echo "==========================================="
    echo "  ❌  FULL INTEGRATION TEST: FAILED        "
    echo "==========================================="
fi

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
echo ""
echo "Cleaning up background processes..."
kill -9 $APP_PID 2>/dev/null || true
kill -9 $WORKER_PID 2>/dev/null || true
echo "Done."
