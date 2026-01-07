variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 4000
}

variable "task_cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

variable "assign_public_ip" {
  description = "Assign public IP to ECS tasks"
  type        = bool
  default     = false
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (null for dev without ALB)"
  type        = string
  default     = null
}

variable "target_group_arn" {
  description = "ARN of the target group (null for dev without ALB)"
  type        = string
  default     = null
}

variable "use_code_deploy" {
  description = "Use CodeDeploy for Blue/Green deployments"
  type        = bool
  default     = false
}

variable "s3_bucket" {
  description = "S3 bucket name for application"
  type        = string
}

# Secret ARNs
variable "secret_arns" {
  description = "List of all secret ARNs"
  type        = list(string)
}

variable "database_secret_arn" {
  description = "ARN of the database secret"
  type        = string
}

variable "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  type        = string
}

variable "oauth_secret_arn" {
  description = "ARN of the OAuth secret"
  type        = string
}

variable "encryption_secret_arn" {
  description = "ARN of the encryption secret"
  type        = string
}

variable "s3_secret_arn" {
  description = "ARN of the S3 secret"
  type        = string
}
