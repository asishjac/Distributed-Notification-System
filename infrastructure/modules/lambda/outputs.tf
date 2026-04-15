output "function_arn" {
  description = "The ARN of the delivery worker Lambda function."
  value       = aws_lambda_function.delivery_worker.arn
}

output "function_name" {
  description = "The name of the delivery worker Lambda function."
  value       = aws_lambda_function.delivery_worker.function_name
}

output "event_source_mapping_uuid" {
  description = "The UUID of the SQS-to-Lambda event source mapping."
  value       = aws_lambda_event_source_mapping.sqs_trigger.uuid
}
