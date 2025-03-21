variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "stock-analysis-cluster"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "stock-data-collector"
}

variable "task_family" {
  description = "Family name for the ECS task"
  type        = string
  default     = "stock-data-collector"
}

variable "kinesis_stream_name" {
  description = "Name of the Kinesis data stream"
  type        = string
  default     = "stock-stream"
}

variable "dynamo_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "stock-table"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "StockAnalysisLambda"
}
