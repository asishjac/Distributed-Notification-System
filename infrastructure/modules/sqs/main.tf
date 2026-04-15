# ---------------------------------------------------------------------------
# SQS Module — Notification Queue + Dead Letter Queue
# ---------------------------------------------------------------------------
# Why DLQ?
# A Dead Letter Queue is a second queue that receives messages which failed
# to be processed after a maximum number of attempts (maxReceiveCount).
# Instead of silently losing the message, it lands in the DLQ where you
# can inspect it, debug it, and replay it manually.
# This is a mandatory production pattern — any senior engineer will expect it.
# ---------------------------------------------------------------------------

# --- Dead Letter Queue (created first so its ARN can be referenced below) ---
resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-notification-dlq-${var.environment}"

  # Retain failed messages for 14 days so we have time to investigate
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "dead-letter-queue"
  }
}

# --- Main Notification Queue ---
resource "aws_sqs_queue" "notification_queue" {
  name = "notification-queue"

  # How long a message is invisible to other consumers while being processed.
  # Set to 60s — if the Lambda doesn't finish in time, the message becomes
  # visible again for retry.
  visibility_timeout_seconds = 60

  # Messages not consumed in 4 days are deleted from the queue
  message_retention_seconds = 345600 # 4 days

  # Redrive policy: after 3 failed processing attempts, route to the DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "main-queue"
  }
}
