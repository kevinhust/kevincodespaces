variable "group_name" {
  description = "Name of the project group"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "s3_bucket" {
  description = "Name of the S3 bucket for web content"
  type        = string
}

variable "ami_id" {
  description = "ID of the AMI to use for web servers"
  type        = string
}

variable "instance_type" {
  description = "Instance type for web servers"
  type        = string
}

variable "web_security_group_id" {
  description = "ID of the web security group"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Map of public subnet IDs"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "Map of private subnet IDs"
  type        = map(string)
}

variable "private_security_group_id" {
  description = "ID of the private security group"
  type        = string
} 