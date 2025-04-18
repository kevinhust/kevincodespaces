variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "group_name" {
  description = "Name of the project group"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnet configurations"
  type = map(object({
    cidr = string
    az   = string
  }))
} 