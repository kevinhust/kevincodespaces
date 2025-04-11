variable "group_name" {
  description = "Name of the project group"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "web_security_group_id" {
  description = "ID of the web security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
} 