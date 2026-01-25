variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Lambda to run in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda (private subnets recommended)"
  type        = list(string)
}

variable "database_secret_arn" {
  description = "ARN of the database secret in Secrets Manager"
  type        = string
}

variable "gemini_secret_arn" {
  description = "ARN of the Gemini secret in Secrets Manager (from translation Lambda module)"
  type        = string
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression for processing"
  type        = string
  default     = "rate(6 hours)"
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 600
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for Lambda"
  type        = number
  default     = 2
}

variable "use_existing_security_group" {
  description = "Use an existing security group instead of creating one"
  type        = bool
  default     = false
}

variable "existing_security_group_id" {
  description = "ID of existing security group to use (required if use_existing_security_group is true)"
  type        = string
  default     = ""
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
