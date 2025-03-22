variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "kinesis_stream_name" {
  description = "Name of the Kinesis stream"
  type        = string
  default     = "stock-stream"
}

variable "dynamo_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "stock-table"
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
  description = "Family name of the ECS task definition"
  type        = string
  default     = "stock-data-collector-task"
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