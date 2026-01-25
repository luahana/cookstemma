variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for images"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for images"
  type        = string
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 1024
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for Lambda"
  type        = number
  default     = 10
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository for Lambda container image"
  type        = string
}

# CloudWatch Alarms
variable "sns_alarm_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms. Required when enable_alarms is true."
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for Lambda monitoring. Requires sns_alarm_topic_arn to be set."
  type        = bool
  default     = true
}

variable "architecture" {
  description = "Lambda architecture (arm64 or x86_64)"
  type        = string
  default     = "arm64"
}
