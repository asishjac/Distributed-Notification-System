# ---------------------------------------------------------------------------
# Root Variables
# ---------------------------------------------------------------------------
# These are the top-level inputs for the entire Terraform configuration.
# They are passed down to child modules as needed.
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "The endpoint URL for LocalStack. Uses Docker network hostname."
  type        = string
  default     = "http://localstack:4566"
}

variable "environment" {
  description = "The deployment environment (local, staging, production)."
  type        = string
  default     = "local"
}

variable "project_name" {
  description = "The name of the project, used as a prefix for resource naming."
  type        = string
  default     = "notification-system"
}
