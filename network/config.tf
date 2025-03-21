terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "kevinw-p2"
    key    = "terraform/network/state"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
