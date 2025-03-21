# S3 Bucket
resource "aws_s3_bucket" "stock_analysis" {
  bucket = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name = var.s3_bucket_name
  }
}

# IAM Role
resource "aws_iam_role" "stock_analysis" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com",
            "sagemaker.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name = var.iam_role_name
  }
}

# IAM Policy for the role
resource "aws_iam_policy" "stock_analysis" {
  name        = "${var.iam_role_name}Policy"
  description = "Policy for Stock Analysis system"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
          "kinesis:*",
          "dynamodb:*",
          "sagemaker:*",
          "logs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "stock_analysis" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = aws_iam_policy.stock_analysis.arn
}

# Kinesis Data Stream
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
    type = "N"
  }

  tags = {
    Name = var.dynamo_table_name
  }
}

# Lambda Function
resource "aws_lambda_function" "stock_analysis" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.stock_analysis.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 512

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DYNAMO_TABLE = var.dynamo_table_name,
      SAGEMAKER_ENDPOINT = "${var.sagemaker_model_name}-endpoint"
    }
  }

  layers = [aws_lambda_layer_version.ta_lib.arn]

  tags = {
    Name = var.lambda_function_name
  }
}

# Lambda Layer
resource "aws_lambda_layer_version" "ta_lib" {
  layer_name = "ta_lib_layer"
  filename   = "ta_lib_layer.zip"
  compatible_runtimes = ["python3.9"]
}

# Lambda Event Source Mapping
resource "aws_lambda_event_source_mapping" "kinesis_mapping" {
  event_source_arn  = aws_kinesis_stream.stock_stream.arn
  function_name     = aws_lambda_function.stock_analysis.function_name
  starting_position = "LATEST"
  batch_size        = 100
}

# SageMaker resources would typically be created here but they require model artifacts
# For this example, I'll create a placeholder for the SageMaker endpoint configuration

# ECS Cluster
resource "aws_ecs_cluster" "stock_analysis" {
  name = var.cluster_name

  tags = {
    Name = var.cluster_name
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "stock_data_collector" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.stock_analysis.arn
  task_role_arn            = aws_iam_role.stock_analysis.arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = "${aws_ecr_repository.stock_data_collector.repository_url}:latest"
      essential = true
      environment = [
        {
          name  = "KINESIS_STREAM_NAME"
          value = var.kinesis_stream_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_name}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = var.task_family
  }
}

# ECR Repository
resource "aws_ecr_repository" "stock_data_collector" {
  name = var.service_name

  tags = {
    Name = var.service_name
  }
}

# ECS Service
resource "aws_ecs_service" "stock_data_collector" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.stock_analysis.id
  task_definition = aws_ecs_task_definition.stock_data_collector.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  tags = {
    Name = var.service_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${var.service_name}"
  retention_in_days = 30

  tags = {
    Name = "/ecs/${var.service_name}"
  }
}
