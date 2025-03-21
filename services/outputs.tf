output "kinesis_stream_arn" {
  description = "ARN of the Kinesis data stream"
  value       = aws_kinesis_stream.stock_stream.arn
}

output "dynamo_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.stock_table.name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.stock_analysis.arn
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.stock_analysis.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.stock_analysis.bucket
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.stock_data_collector.repository_url
}
