terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend — state is stored in the mounted volume so it persists across
  # docker-compose restarts. No remote state needed for local development.
  backend "local" {
    path = "/infrastructure/terraform.tfstate"
  }
}

# ---------------------------------------------------------------------------
# AWS Provider — pointed at LocalStack
# ---------------------------------------------------------------------------
# Every AWS API call Terraform makes will be routed to the LocalStack container
# instead of the real AWS cloud. The fake credentials match LocalStack's defaults.
# ---------------------------------------------------------------------------
provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  # LocalStack does not implement the full AWS metadata/credential chain,
  # so we skip the validations that would fail against it.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Route every AWS service endpoint to LocalStack
  endpoints {
    sqs      = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    lambda   = var.localstack_endpoint
    iam      = var.localstack_endpoint
    s3       = var.localstack_endpoint
  }
}
