provider "aws" {
  region = var.aws_region
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
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com"
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
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
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
    type = "N"
  }

  tags = {
    Name = var.dynamo_table_name
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "stock_analysis" {
  name = var.cluster_name

  tags = {
    Name = var.cluster_name
  }
}

# ECR Repository
resource "aws_ecr_repository" "stock_data_collector" {
  name = var.service_name

  tags = {
    Name = var.service_name
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
  task_role_arn           = aws_iam_role.stock_analysis.arn

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
}

# ECS Service
resource "aws_ecs_service" "stock_data_collector" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.stock_analysis.id
  task_definition = aws_ecs_task_definition.stock_data_collector.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.public_subnet_id]
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 30

  tags = {
    Name = "/ecs/${var.service_name}"
  }
}

# Lambda Function
resource "aws_lambda_function" "stock_analysis" {
  filename         = "lambda_function.zip"
  function_name    = var.lambda_function_name
  role            = aws_iam_role.stock_analysis.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      DYNAMO_TABLE = var.dynamo_table_name
    }
  }

  vpc_config {
    subnet_ids         = [var.public_subnet_id]
    security_group_ids = [var.ecs_security_group_id]
  }
}

# Lambda Event Source Mapping
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.stock_stream.arn
  function_name     = aws_lambda_function.stock_analysis.arn
  starting_position = "LATEST"
  batch_size        = 100
}
