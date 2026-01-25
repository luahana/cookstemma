# ECS Frontend Module Outputs

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.web.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.web.name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.web.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.web.arn
}

output "security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = local.ecs_web_security_group_id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.web.name
}
