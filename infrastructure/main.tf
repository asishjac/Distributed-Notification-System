# ---------------------------------------------------------------------------
# Root Module
# ---------------------------------------------------------------------------
# This is the entry point for Terraform. It orchestrates all child modules.
# Each module is responsible for a single AWS service, keeping concerns
# cleanly separated — exactly like packages in a Kotlin codebase.
# ---------------------------------------------------------------------------

module "sqs" {
  source = "./modules/sqs"

  environment  = var.environment
  project_name = var.project_name
}

module "dynamodb" {
  source = "./modules/dynamodb"

  environment  = var.environment
  project_name = var.project_name
}

module "lambda" {
  source = "./modules/lambda"

  environment       = var.environment
  project_name      = var.project_name
  aws_region        = var.aws_region
  sqs_queue_arn     = module.sqs.queue_arn
  dynamodb_table_arn = module.dynamodb.table_arn
  dynamodb_table_name = module.dynamodb.table_name
}
