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

variable "firebase_secret_arn" {
  description = "ARN of the Firebase secret"
  type        = string
}

variable "cdn_url_prefix" {
  description = "CDN URL prefix for image URLs (CloudFront domain)"
  type        = string
  default     = ""
}

# SQS Configuration for Translation
variable "sqs_translation_queue_url" {
  description = "URL of the SQS queue for translation events"
  type        = string
  default     = ""
}

variable "sqs_translation_queue_arn" {
  description = "ARN of the SQS queue for translation events"
  type        = string
  default     = ""
}

variable "sqs_enabled" {
  description = "Enable SQS push for real-time translations"
  type        = bool
  default     = true
}

# CloudWatch Alarms
variable "sns_alarm_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms. Required when enable_alarms is true."
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for ECS monitoring. Requires sns_alarm_topic_arn to be set."
  type        = bool
  default     = true
}

# Service Discovery
variable "service_discovery_service_arn" {
  description = "ARN of the service discovery service for registration"
  type        = string
  default     = ""
}

variable "cpu_architecture" {
  description = "CPU architecture for ECS tasks (X86_64 or ARM64)"
  type        = string
  default     = "ARM64"
}

variable "additional_ingress_security_group_ids" {
  description = "Additional security group IDs allowed to access the container port (e.g., web ECS tasks)"
  type        = list(string)
  default     = []
}

# Sentry
variable "sentry_dsn" {
  description = "Sentry DSN for error tracking"
  type        = string
  default     = ""
}

variable "sentry_environment" {
  description = "Sentry environment tag"
  type        = string
  default     = ""
}
