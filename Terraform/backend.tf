terraform {
  backend "s3" {
    bucket         = "zombies-acs730"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "zombies-acs730"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
} 