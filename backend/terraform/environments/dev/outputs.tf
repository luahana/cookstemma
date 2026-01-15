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

# Frontend outputs
output "frontend_ecr_repository_url" {
  description = "Frontend ECR repository URL"
  value       = data.aws_ecr_repository.frontend.repository_url
}

output "frontend_ecs_cluster_name" {
  description = "Name of the frontend ECS cluster"
  value       = module.ecs_frontend.cluster_name
}

output "frontend_ecs_service_name" {
  description = "Name of the frontend ECS service"
  value       = module.ecs_frontend.service_name
}

output "frontend_cloudwatch_log_group" {
  description = "Frontend CloudWatch log group name"
  value       = module.ecs_frontend.log_group_name
}

output "frontend_endpoint" {
  description = "Frontend URL (HTTP)"
  value       = "http://${module.alb.alb_dns_name}"
}
