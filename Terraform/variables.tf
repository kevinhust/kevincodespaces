variable "group_name" {
  description = "Name of the group/team"
  type        = string
  default     = "zombies"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
}

variable "public_subnet_3_cidr" {
  description = "CIDR block for public subnet 3"
  type        = string
}

variable "public_subnet_4_cidr" {
  description = "CIDR block for public subnet 4"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
}

variable "availability_zone_1" {
  description = "Availability zone 1"
  type        = string
}

variable "availability_zone_2" {
  description = "Availability zone 2"
  type        = string
}

variable "availability_zone_3" {
  description = "Availability zone 3"
  type        = string
}

variable "availability_zone_4" {
  description = "Availability zone 4"
  type        = string
}

variable "s3_bucket" {
  description = "Name of the S3 bucket for web content"
  type        = string
  default     = "thezombiesofacs730"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t2.small"
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

variable "ssh_public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "zombies-key"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
  default     = "acs730-project"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "zombies-team"
}

variable "managed_by" {
  description = "Tool managing the resources"
  type        = string
  default     = "terraform"
}