output "table_name" {
  description = "The name of the DynamoDB delivery logs table."
  value       = aws_dynamodb_table.delivery_logs.name
}

output "table_arn" {
  description = "The ARN of the DynamoDB delivery logs table."
  value       = aws_dynamodb_table.delivery_logs.arn
}
