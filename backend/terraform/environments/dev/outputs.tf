output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "rds_address" {
  description = "RDS address (hostname only)"
  value       = module.rds.address
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = data.aws_ecr_repository.main.repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.ecs.log_group_name
}

output "alb_dns_name" {
  description = "ALB DNS name - use this as your API endpoint"
  value       = module.alb.alb_dns_name
}

output "api_endpoint" {
  description = "API endpoint URL (HTTP)"
  value       = "http://${module.alb.alb_dns_name}/api/v1"
}

# Web outputs
output "web_ecr_repository_url" {
  description = "Web ECR repository URL"
  value       = data.aws_ecr_repository.web.repository_url
}

output "web_ecs_cluster_name" {
  description = "Name of the web ECS cluster"
  value       = module.ecs_web.cluster_name
}

output "web_ecs_service_name" {
  description = "Name of the web ECS service"
  value       = module.ecs_web.service_name
}

output "web_cloudwatch_log_group" {
  description = "Web CloudWatch log group name"
  value       = module.ecs_web.log_group_name
}

output "web_endpoint" {
  description = "Web URL (HTTP)"
  value       = "http://${module.alb.alb_dns_name}"
}

# Translation Lambda outputs
output "translation_lambda_arn" {
  description = "ARN of the translation Lambda function"
  value       = module.lambda_translation.lambda_function_arn
}

output "translation_sqs_queue_url" {
  description = "URL of the translation SQS queue"
  value       = module.lambda_translation.sqs_queue_url
}

# Image processing outputs
output "image_processor_lambda_arn" {
  description = "ARN of the image processor Lambda"
  value       = module.lambda_image_processing.processor_lambda_arn
}

output "image_processing_sqs_queue_url" {
  description = "URL of the image processing SQS queue"
  value       = module.lambda_image_processing.sqs_queue_url
}

# CloudFront outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.cloudfront.distribution_domain_name
}

output "cdn_url" {
  description = "CDN URL for images"
  value       = module.cloudfront.cdn_url
}

# DNS outputs
output "dev_domain" {
  description = "Dev environment domain name"
  value       = var.create_dns_record ? "${var.environment}.${var.domain_name}" : null
}

output "dev_url" {
  description = "Dev environment URL (HTTP)"
  value       = var.create_dns_record ? "http://${var.environment}.${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

output "dev_api_url" {
  description = "Dev API URL"
  value       = var.create_dns_record ? "http://${var.environment}.${var.domain_name}/api/v1" : "http://${module.alb.alb_dns_name}/api/v1"
}

# CloudWatch Alarms outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.name
}

# Keyword Generator Lambda outputs
output "keyword_generator_lambda_arn" {
  description = "ARN of the keyword generator Lambda function"
  value       = module.lambda_keyword_generator.lambda_function_arn
}

output "keyword_generator_lambda_name" {
  description = "Name of the keyword generator Lambda function"
  value       = module.lambda_keyword_generator.lambda_function_name
}

output "keyword_generator_eventbridge_rule_arn" {
  description = "ARN of the keyword generator EventBridge schedule rule"
  value       = module.lambda_keyword_generator.eventbridge_rule_arn
}
