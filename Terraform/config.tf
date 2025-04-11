terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "zombies-acs730"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "zombies-acs730"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Team      = "zombies"
      Project   = "ACS730"
      Terraform = "true"
    }
  }
} 