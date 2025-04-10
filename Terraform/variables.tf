variable "group_name" {
  description = "Name of the project group"
  type        = string
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
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
}

variable "ami_id" {
  description = "ID of the AMI to use for web servers"
  type        = string
}

variable "instance_type" {
  description = "Instance type for web servers"
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