variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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

variable "push_to_kinesis_lambda_name" {
  description = "Name of the push-to-kinesis Lambda function"
  type        = string
  default     = "push-to-kinesis"
}

variable "process_stock_data_lambda_name" {
  description = "Name of the process-stock-data Lambda function"
  type        = string
  default     = "process-stock-data"
}

variable "trigger_training_job_lambda_name" {
  description = "Name of the trigger-training-job Lambda function"
  type        = string
  default     = "trigger-training-job"
}

variable "sagemaker_model_name" {
  description = "Name of the SageMaker model"
  type        = string
  default     = "stock-prediction"
}

variable "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  type        = string
  default     = "stock-prediction-endpoint"
}

variable "ticker_symbol" {
  description = "Stock ticker symbol for push-to-kinesis Lambda"
  type        = string
  default     = "TSLA"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "kevinw-p2"
}