variable "environment" {
  description = "The deployment environment (local, staging, production)."
  type        = string
}

variable "project_name" {
  description = "The project name prefix for resource naming."
  type        = string
}

variable "aws_region" {
  description = "The AWS region for the Lambda function."
  type        = string
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue the Lambda will consume from."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table the Lambda will write to."
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table (passed as an env var to the Lambda)."
  type        = string
}
