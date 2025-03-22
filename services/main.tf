provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "kevinw-p2"
    key    = "terraform/network/state"
    region = "us-east-1"
  }
}

# IAM Role
resource "aws_iam_role" "stock_analysis" {
  name = "StockAnalysisRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "sagemaker.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# IAM Policies
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "stock_analysis" {
  name = "StockAnalysisPolicy"
  role = aws_iam_role.stock_analysis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "kinesis:*",
          "dynamodb:*",
          "logs:*",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "sagemaker:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 Bucket
resource "aws_s3_bucket" "stock_bucket" {
  bucket = var.bucket_name
}

# 上传 SageMaker 脚本
resource "aws_s3_object" "code_inference" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "code/inference.py"
  source = "path/to/inference.py"
}

resource "aws_s3_object" "code_train" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "code/train.py"
  source = "path/to/train.py"
}

resource "aws_s3_object" "code_requirements" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "code/requirements.txt"
  source = "path/to/code_requirements.txt"
}

# 上传历史数据
resource "aws_s3_object" "data_tsla" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "data/tsla_history.csv"
  source = "path/to/tsla_history.csv"
}

# 上传 Lambda 部署包
resource "aws_s3_object" "push_to_kinesis_zip" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "lambda/push_to_kinesis/push_to_kinesis.zip"
  source = "path/to/push_to_kinesis.zip"
}

resource "aws_s3_object" "process_stock_data_zip" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "lambda/process_stock_data/process_stock_data.zip"
  source = "path/to/process_stock_data.zip"
}

resource "aws_s3_object" "trigger_training_job_zip" {
  bucket = aws_s3_bucket.stock_bucket.bucket
  key    = "lambda/trigger_training_job/trigger_training_job.zip"
  source = "path/to/trigger_training_job.zip"
}

# Kinesis Stream
resource "aws_kinesis_stream" "stock_stream" {
  name             = var.kinesis_stream_name
  shard_count      = 1
  retention_period = 24

  tags = {
    Name = var.kinesis_stream_name
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "stock_table" {
  name           = var.dynamo_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "stock_symbol"
  range_key      = "timestamp"

  attribute {
    name = "stock_symbol"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"  # 改为字符串类型，与代码中的 timestamp 格式一致
  }

  tags = {
    Name = var.dynamo_table_name
  }
}

# push-to-kinesis Lambda
resource "aws_lambda_function" "push_to_kinesis" {
  function_name = var.push_to_kinesis_lambda_name
  s3_bucket     = var.bucket_name
  s3_key        = "lambda/push_to_kinesis/push_to_kinesis.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.stock_analysis.arn
  timeout       = 30

  environment {
    variables = {
      TICKER_SYMBOL       = var.ticker_symbol
      KINESIS_STREAM_NAME = var.kinesis_stream_name
    }
  }

  vpc_config {
    subnet_ids         = [data.terraform_remote_state.network.outputs.private_subnet_id]
    security_group_ids = [data.terraform_remote_state.network.outputs.lambda_security_group_id]
  }

  tags = {
    Name = var.push_to_kinesis_lambda_name
  }
}

# CloudWatch Events 触发 push-to-kinesis
resource "aws_cloudwatch_event_rule" "trigger_push_to_kinesis" {
  name                = "trigger-push-to-kinesis"
  description         = "Trigger Lambda every 10 seconds"
  schedule_expression = "rate(10 seconds)"
}

resource "aws_cloudwatch_event_target" "push_to_kinesis_target" {
  rule      = aws_cloudwatch_event_rule.trigger_push_to_kinesis.name
  target_id = "push-to-kinesis"
  arn       = aws_lambda_function.push_to_kinesis.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_push" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.push_to_kinesis.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_push_to_kinesis.arn
}

# process-stock-data Lambda
resource "aws_lambda_function" "process_stock_data" {
  function_name = var.process_stock_data_lambda_name
  s3_bucket     = var.bucket_name
  s3_key        = "lambda/process_stock_data/process_stock_data.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.stock_analysis.arn
  timeout       = 30
  memory_size   = 512

  environment {
    variables = {
      DYNAMODB_TABLE_NAME   = var.dynamo_table_name
      SAGEMAKER_ENDPOINT_NAME = var.sagemaker_endpoint_name
    }
  }

  vpc_config {
    subnet_ids         = [data.terraform_remote_state.network.outputs.private_subnet_id]
    security_group_ids = [data.terraform_remote_state.network.outputs.lambda_security_group_id]
  }

  tags = {
    Name = var.process_stock_data_lambda_name
  }
}

# Kinesis 触发 process-stock-data
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn = aws_kinesis_stream.stock_stream.arn
  function_name    = aws_lambda_function.process_stock_data.arn
  starting_position = "LATEST"
}

# trigger-training-job Lambda
resource "aws_lambda_function" "trigger_training_job" {
  function_name = var.trigger_training_job_lambda_name
  s3_bucket     = var.bucket_name
  s3_key        = "lambda/trigger_training_job/trigger_training_job.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.stock_analysis.arn
  timeout       = 30

  environment {
    variables = {
      SAGEMAKER_ROLE_ARN = aws_iam_role.stock_analysis.arn
    }
  }

  vpc_config {
    subnet_ids         = [data.terraform_remote_state.network.outputs.private_subnet_id]
    security_group_ids = [data.terraform_remote_state.network.outputs.lambda_security_group_id]
  }

  tags = {
    Name = var.trigger_training_job_lambda_name
  }
}

# EventBridge 触发 trigger-training-job
resource "aws_cloudwatch_event_rule" "trigger_training_job" {
  name                = "trigger-training-job"
  description         = "Trigger Lambda every 3 days"
  schedule_expression = "cron(0 0 */3 * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_training_job_target" {
  rule      = aws_cloudwatch_event_rule.trigger_training_job.name
  target_id = "trigger-training-job"
  arn       = aws_lambda_function.trigger_training_job.arn
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_trigger" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_training_job.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_training_job.arn
}

# SageMaker Model
resource "aws_sagemaker_model" "stock_prediction_model" {
  name               = var.sagemaker_model_name
  execution_role_arn = aws_iam_role.stock_analysis.arn

  primary_container {
    image = "811284229777.dkr.ecr.us-east-1.amazonaws.com/xgboost:latest"
    model_data_url = "s3://${var.bucket_name}/output/model-2025-03-22.tar.gz"
  }
}

# SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "stock_prediction_config" {
  name = "${var.sagemaker_model_name}-endpoint-config"

  production_variants {
    variant_name           = "variant-1"
    model_name             = aws_sagemaker_model.stock_prediction_model.name
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
  }
}

# SageMaker Endpoint
resource "aws_sagemaker_endpoint" "stock_prediction" {
  name                 = var.sagemaker_endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.stock_prediction_config.name
}