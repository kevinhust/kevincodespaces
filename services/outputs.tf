output "kinesis_stream_name" {
  value = aws_kinesis_stream.stock_stream.name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.stock_table.name
}

output "push_to_kinesis_lambda_name" {
  value = aws_lambda_function.push_to_kinesis.function_name
}

output "process_stock_data_lambda_name" {
  value = aws_lambda_function.process_stock_data.function_name
}

output "trigger_training_job_lambda_name" {
  value = aws_lambda_function.trigger_training_job.function_name
}

output "sagemaker_endpoint_name" {
  value = aws_sagemaker_endpoint.stock_prediction.name
}