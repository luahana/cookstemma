output "processor_lambda_arn" {
  description = "ARN of the image processor Lambda function"
  value       = aws_lambda_function.processor.arn
}

output "processor_lambda_name" {
  description = "Name of the image processor Lambda function"
  value       = aws_lambda_function.processor.function_name
}

output "orchestrator_lambda_arn" {
  description = "ARN of the orchestrator Lambda function"
  value       = aws_lambda_function.orchestrator.arn
}

output "orchestrator_lambda_name" {
  description = "Name of the orchestrator Lambda function"
  value       = aws_lambda_function.orchestrator.function_name
}

output "sqs_queue_url" {
  description = "URL of the image processing SQS queue"
  value       = aws_sqs_queue.image_processing.url
}

output "sqs_queue_arn" {
  description = "ARN of the image processing SQS queue"
  value       = aws_sqs_queue.image_processing.arn
}

output "sqs_dlq_url" {
  description = "URL of the image processing dead letter queue"
  value       = aws_sqs_queue.image_processing_dlq.url
}

output "sqs_dlq_arn" {
  description = "ARN of the image processing dead letter queue"
  value       = aws_sqs_queue.image_processing_dlq.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Lambda container"
  value       = var.ecr_repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for the processor Lambda"
  value       = aws_cloudwatch_log_group.processor.name
}
