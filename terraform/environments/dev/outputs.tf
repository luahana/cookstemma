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

# Note: For dev, access the application via ECS task public IP on port 4000
# Use AWS Console or CLI to get the task's public IP:
# aws ecs list-tasks --cluster pairing-planet-dev-cluster
# aws ecs describe-tasks --cluster pairing-planet-dev-cluster --tasks <task-arn>
