output "lambda_function_arn" {
  description = "ARN of the keyword generator Lambda function"
  value       = aws_lambda_function.keyword_generator.arn
}

output "lambda_function_name" {
  description = "Name of the keyword generator Lambda function"
  value       = aws_lambda_function.keyword_generator.function_name
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
  value       = var.ecr_repository_url
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge schedule rule"
  value       = aws_cloudwatch_event_rule.schedule.arn
}
