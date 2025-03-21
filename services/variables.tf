variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "project_name" {
  description = "Name of the project for tagging"
  type        = string
  default     = "stock-analysis"
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

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "kevinw-p2"
}

variable "iam_role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "StockAnalysisRole"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "StockAnalysisLambda"
}

variable "sagemaker_model_name" {
  description = "Name of the SageMaker model"
  type        = string
  default     = "tsla-stock-predictor"
}
