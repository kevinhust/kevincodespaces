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
            "ecs-tasks.amazonaws.com",
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

resource "aws_iam_policy" "sagemaker_access_policy" {
  name        = "SageMakerAccessPolicy"
  description = "Policy for SageMaker operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:DescribeEndpoint",
          "sagemaker:InvokeEndpoint"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:List*",
          "sagemaker:Get*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::039444453392:role/StockAnalysisRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = aws_iam_policy.sagemaker_access_policy.arn
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy for accessing specific S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::kevinw-p2",
          "arn:aws:s3:::kevinw-p2/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "kinesis_policy" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

# 添加 ECR 权限
resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  role       = aws_iam_role.stock_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
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
          "kinesis:*",
          "dynamodb:*",
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

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "stock_data_collector_lifecycle" {
  repository = aws_ecr_repository.stock_data_collector.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images older than 30 days",
      "selection": {
        "tagStatus": "any",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

# 下载 push_to_kinesis.py 从 S3
resource "null_resource" "download_push_to_kinesis" {
  provisioner "local-exec" {
    command = "aws s3 cp s3://kevinw-p2/code/push_to_kinesis.py ./push_to_kinesis.py"
  }
}

# 创建 Dockerfile
resource "local_file" "dockerfile" {
  content = <<EOF
FROM python:3.9-slim
WORKDIR /app
COPY push_to_kinesis.py .
RUN pip install boto3
CMD ["python", "push_to_kinesis.py"]
EOF
  filename = "Dockerfile"
}

# 构建并推送 Docker 镜像
resource "null_resource" "build_and_push_image" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 039444453392.dkr.ecr.us-east-1.amazonaws.com
      docker build -t stock-data-collector .
      docker tag stock-data-collector:latest 039444453392.dkr.ecr.us-east-1.amazonaws.com/stock-data-collector:latest
      docker push 039444453392.dkr.ecr.us-east-1.amazonaws.com/stock-data-collector:latest
    EOT
  }

  depends_on = [
    aws_ecr_repository.stock_data_collector,
    null_resource.download_push_to_kinesis,
    local_file.dockerfile
  ]
}

# ECS Task Definition
resource "aws_ecs_task_definition" "stock_data_collector" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
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
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = "us-east-1"
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

  depends_on = [null_resource.build_and_push_image]
}

# ECS Service
resource "aws_ecs_service" "stock_data_collector" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.stock_analysis.id
  task_definition = aws_ecs_task_definition.stock_data_collector.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.terraform_remote_state.network.outputs.public_subnet_id]
    security_groups  = [data.terraform_remote_state.network.outputs.ecs_security_group_id]
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

# Lambda 函数：触发 SageMaker 训练作业
resource "aws_lambda_function" "trigger_training_job" {
  function_name = "TriggerSageMakerTrainingJob"
  role          = aws_iam_role.stock_analysis.arn
  handler       = "trigger_training_job.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  s3_bucket = "kevinw-p2"
  s3_key    = "trigger_training_job.zip"

  tags = {
    Name = "TriggerSageMakerTrainingJob"
  }
}

# 触发 Lambda 函数
resource "null_resource" "invoke_training_job_lambda" {
  provisioner "local-exec" {
    command = <<EOT
      aws lambda invoke \
        --function-name TriggerSageMakerTrainingJob \
        --region us-east-1 \
        --payload '{}' \
        response.json
      cat response.json | jq -r '.body' | jq -r '.training_job_name' > training_job_name.txt
    EOT
  }

  depends_on = [aws_lambda_function.trigger_training_job]
}

# 等待训练作业完成
resource "null_resource" "wait_for_training_job" {
  provisioner "local-exec" {
    command = <<EOT
      TRAINING_JOB_NAME=$(cat training_job_name.txt)
      if [ -z "$TRAINING_JOB_NAME" ]; then
        echo "Error: Training job name is empty"
        exit 1
      fi
      aws sagemaker wait training-job-completed-or-stopped \
        --training-job-name $TRAINING_JOB_NAME \
        --region us-east-1
    EOT
  }

  depends_on = [null_resource.invoke_training_job_lambda]
}

# SageMaker 模型
resource "aws_sagemaker_model" "model" {
  name               = var.sagemaker_model_name
  execution_role_arn = "arn:aws:iam::039444453392:role/StockAnalysisRole"

  primary_container {
    image          = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:1.0-1-cpu-py3"
    model_data_url = "s3://kevinw-p2/output/model.tar.gz"
    environment = {
      SAGEMAKER_PROGRAM = "inference.py"
    }
  }

  depends_on = [null_resource.wait_for_training_job]
}

# SageMaker 端点配置
resource "aws_sagemaker_endpoint_configuration" "endpoint_config" {
  name = "${var.sagemaker_model_name}-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.model.name
    initial_instance_count = 1
    instance_type          = "ml.m5.large"
  }
}

# SageMaker 端点
resource "aws_sagemaker_endpoint" "endpoint" {
  name                 = "${var.sagemaker_model_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpoint_config.name
}

# Lambda Function（用于 Kinesis 触发）
resource "aws_lambda_function" "stock_analysis" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.stock_analysis.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 512

  s3_bucket = "kevinw-p2"
  s3_key    = "lambda_function.zip"

  environment {
    variables = {
      DYNAMO_TABLE       = var.dynamo_table_name
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
  compatible_runtimes = ["python3.9"]

  s3_bucket = "kevinw-p2"
  s3_key    = "ta_lib_layer.zip"
}

# Lambda Event Source Mapping
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.stock_stream.arn
  function_name     = aws_lambda_function.stock_analysis.arn
  starting_position = "LATEST"
  batch_size        = 100
}