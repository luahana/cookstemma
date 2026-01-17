output "lambda_function_arn" {
  description = "ARN of the translation Lambda function"
  value       = aws_lambda_function.translator.arn
}

output "lambda_function_name" {
  description = "Name of the translation Lambda function"
  value       = aws_lambda_function.translator.function_name
}

output "sqs_queue_url" {
  description = "URL of the translation SQS queue"
  value       = aws_sqs_queue.translation_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the translation SQS queue"
  value       = aws_sqs_queue.translation_queue.arn
}

output "sqs_dlq_url" {
  description = "URL of the translation dead letter queue"
  value       = aws_sqs_queue.translation_dlq.url
}

output "openai_secret_arn" {
  description = "ARN of the OpenAI secret"
  value       = aws_secretsmanager_secret.openai.arn
}

output "lambda_security_group_id" {
  description = "Security group ID for the Lambda function"
  value       = local.lambda_security_group_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Lambda container"
  value       = aws_ecr_repository.translator.repository_url
}
