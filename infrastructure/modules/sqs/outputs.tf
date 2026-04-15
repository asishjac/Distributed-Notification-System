output "queue_url" {
  description = "The URL of the main notification SQS queue."
  value       = aws_sqs_queue.notification_queue.url
}

output "queue_arn" {
  description = "The ARN of the main notification SQS queue."
  value       = aws_sqs_queue.notification_queue.arn
}

output "queue_name" {
  description = "The name of the main notification SQS queue."
  value       = aws_sqs_queue.notification_queue.name
}

output "dlq_url" {
  description = "The URL of the Dead Letter Queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "The ARN of the Dead Letter Queue."
  value       = aws_sqs_queue.dlq.arn
}
