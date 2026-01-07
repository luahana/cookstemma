output "app_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.main.name
}

output "app_id" {
  description = "ID of the CodeDeploy application"
  value       = aws_codedeploy_app.main.id
}

output "deployment_group_name" {
  description = "Name of the deployment group"
  value       = aws_codedeploy_deployment_group.main.deployment_group_name
}

output "deployment_group_id" {
  description = "ID of the deployment group"
  value       = aws_codedeploy_deployment_group.main.id
}

output "service_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy.arn
}
