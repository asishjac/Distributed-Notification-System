# ---------------------------------------------------------------------------
# Lambda Module — Delivery Worker Function
# ---------------------------------------------------------------------------
# This module deploys the delivery-worker Shadow JAR as an AWS Lambda function
# and wires it up to consume from the SQS notification queue.
#
# The JAR is mounted into the Terraform container at /artifacts/ via the
# docker-compose volume, so Terraform can read and upload it to LocalStack.
# ---------------------------------------------------------------------------

# The Shadow JAR (Uber JAR) built by: ./gradlew shadowJar
# Path inside the Terraform container (mounted via docker-compose volume)
locals {
  jar_path = "/artifacts/delivery-worker.jar"
}

resource "aws_lambda_function" "delivery_worker" {
  function_name = "${var.project_name}-delivery-worker-${var.environment}"
  description   = "Processes SQS notification events and logs delivery status to DynamoDB."

  # The Shadow JAR is uploaded directly to LocalStack as the function code
  filename         = local.jar_path
  source_code_hash = filebase64sha256(local.jar_path)

  # The fully-qualified handler class — matches our Kotlin implementation
  handler = "com.showcase.notification.worker.DeliveryWorkerHandler"

  # Java 21 runtime — ensured compatibility with LocalStack 3.4+ sandbox
  runtime = "java21"

  # IAM role created in iam.tf
  role = aws_iam_role.lambda_exec.arn

  # Lambda needs enough memory and time to process a batch of SQS messages.
  # 512 MB is comfortable for a JVM Lambda — the JVM startup overhead is
  # amortized across the batch.
  memory_size = 512
  timeout     = 60 # seconds — must be >= SQS visibility_timeout / batch_size

  # Snap Start is a AWS feature that pre-initialises the Lambda execution
  # environment after each deployment, eliminating cold-start latency for JVM.
  # LocalStack ignores this but it's good practice to declare it.
  snap_start {
    apply_on = "PublishedVersions"
  }

  # Environment variables the worker reads at runtime
  environment {
    variables = {
      AWS_REGION             = var.aws_region
      AWS_ENDPOINT_URL_DYNAMODB = "http://localstack:4566"
      AWS_ENDPOINT_URL          = "http://localstack:4566"
      DYNAMODB_TABLE_NAME       = var.dynamodb_table_name
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}

# ---------------------------------------------------------------------------
# Event Source Mapping — SQS → Lambda
# ---------------------------------------------------------------------------
# This is the "glue" that tells AWS (LocalStack) to automatically invoke the
# Lambda function when messages arrive in the SQS queue.
# batch_size = 10 means Lambda can receive up to 10 messages per invocation,
# which our worker already handles concurrently with Kotlin Coroutines.
# ---------------------------------------------------------------------------
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.delivery_worker.arn
  batch_size       = 10
  enabled          = true

  # Report partial failures — if 3 out of 10 messages fail, only those 3
  # go to the DLQ. The other 7 are deleted from the queue (success).
  function_response_types = ["ReportBatchItemFailures"]
}
