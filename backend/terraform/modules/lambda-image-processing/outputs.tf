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

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.image_processing.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.image_processing.name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Lambda container"
  value       = aws_ecr_repository.image_processor.repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for the processor Lambda"
  value       = aws_cloudwatch_log_group.processor.name
}
