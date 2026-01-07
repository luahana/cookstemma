variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "prod_listener_arn" {
  description = "ARN of the production listener (HTTPS on 443)"
  type        = string
}

variable "test_listener_arn" {
  description = "ARN of the test listener (HTTPS on 8443)"
  type        = string
  default     = null
}

variable "target_group_blue_name" {
  description = "Name of the blue target group"
  type        = string
}

variable "target_group_green_name" {
  description = "Name of the green target group"
  type        = string
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
}

variable "termination_wait_time" {
  description = "Minutes to wait before terminating old tasks"
  type        = number
  default     = 5
}
