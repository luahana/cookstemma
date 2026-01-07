output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53)"
  value       = module.alb.alb_zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = module.codedeploy.app_name
}

output "codedeploy_deployment_group" {
  description = "CodeDeploy deployment group name"
  value       = module.codedeploy.deployment_group_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = data.aws_ecr_repository.main.repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.ecs.log_group_name
}
