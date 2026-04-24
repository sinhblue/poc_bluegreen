terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "poc-bluegreen-tfstate"
    key            = "terraform/state.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "POC Blue/Green"
      Environment = "dev"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}
