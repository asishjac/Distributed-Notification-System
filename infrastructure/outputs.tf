# ---------------------------------------------------------------------------
# Root Outputs
# ---------------------------------------------------------------------------
# These are the values printed after `terraform apply` and accessible via
# `terraform output`. They provide the connection details that other systems
# (like the Gateway application.yml) would consume.
# ---------------------------------------------------------------------------

output "sqs_queue_url" {
  description = "The URL of the main notification SQS queue."
  value       = module.sqs.queue_url
}

output "sqs_dlq_url" {
  description = "The URL of the Dead Letter Queue for failed notifications."
  value       = module.sqs.dlq_url
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB delivery logs table."
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB delivery logs table."
  value       = module.dynamodb.table_arn
}

output "lambda_function_arn" {
  description = "The ARN of the delivery worker Lambda function."
  value       = module.lambda.function_arn
}

output "lambda_function_name" {
  description = "The name of the delivery worker Lambda function."
  value       = module.lambda.function_name
}
