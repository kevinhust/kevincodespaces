terraform {
  backend "s3" {
    bucket         = "zombies-acs730"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "zombies-id-lock"
  }
} 