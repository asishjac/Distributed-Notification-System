# ---------------------------------------------------------------------------
# Lambda IAM — Role and Policies
# ---------------------------------------------------------------------------
# AWS requires every Lambda function to have an IAM execution role.
# This role defines exactly what AWS resources the Lambda is ALLOWED to access.
# The principle of least privilege: grant only the minimum permissions needed.
#
# Our Lambda needs:
#   1. Basic execution (write logs to CloudWatch)
#   2. SQS read access (receive + delete messages from the queue)
#   3. DynamoDB write access (put items into the delivery logs table)
# ---------------------------------------------------------------------------

# --- Execution Role ---
# The trust policy below allows the Lambda service to assume this role.
resource "aws_iam_role" "lambda_exec" {
  name        = "${var.project_name}-delivery-worker-role-${var.environment}"
  description = "Execution role for the delivery worker Lambda function."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# --- Policy 1: Basic Lambda Execution (CloudWatch Logs) ---
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Policy 2: SQS Read Access ---
# The Lambda needs to receive messages from the queue and delete them after
# processing. GetQueueAttributes is needed for the event source mapping health check.
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "${var.project_name}-lambda-sqs-policy-${var.environment}"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# --- Policy 3: DynamoDB Write Access ---
# The Lambda writes delivery log records. It only needs PutItem.
# We deliberately do NOT grant Read, Scan, or Delete — least privilege.
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-lambda-dynamodb-policy-${var.environment}"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}
