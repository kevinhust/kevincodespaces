output "kinesis_stream_arn" {
  description = "ARN of the Kinesis data stream"
  value       = aws_kinesis_stream.stock_stream.arn
}

output "dynamo_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.stock_table.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.stock_data_collector.repository_url
}
