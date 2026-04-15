variable "environment" {
  description = "The deployment environment (local, staging, production)."
  type        = string
}

variable "project_name" {
  description = "The project name prefix for resource naming."
  type        = string
}
