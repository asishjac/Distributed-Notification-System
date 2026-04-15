# ---------------------------------------------------------------------------
# DynamoDB Module — Notification Delivery Logs Table
# ---------------------------------------------------------------------------
# Why DynamoDB (not PostgreSQL)?
# We already use PostgreSQL for User Preferences — structured, relational data
# that changes rarely. Delivery logs are different: pure append-only events
# at potentially millions per day. DynamoDB guarantees single-digit millisecond
# writes regardless of table size, making it the industry standard for this
# type of high-velocity event logging.
#
# Key Design:
#   Partition Key (PK): userId — allows fast lookups of "all notifications for user X"
#   Sort Key (SK):      traceId — guarantees uniqueness per notification event
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "delivery_logs" {
  name         = "NotificationDeliveryLogs"
  billing_mode = "PAY_PER_REQUEST" # Serverless — no capacity planning needed

  # Primary key: userId (PK) + traceId (SK)
  hash_key  = "userId"
  range_key = "traceId"

  attribute {
    name = "userId"
    type = "S" # String
  }

  attribute {
    name = "traceId"
    type = "S" # String
  }

  # TTL — automatically delete old log records after a set time.
  # The worker writes an `expiresAt` epoch timestamp, and DynamoDB deletes
  # the item once that timestamp has passed. This keeps storage costs low
  # without any cron jobs or maintenance tasks.
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Description = "Stores notification delivery receipts for audit and tracing"
  }
}
