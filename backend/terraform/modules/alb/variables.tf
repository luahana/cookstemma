variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 4000
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/actuator/health"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = null
}

# Frontend configuration
variable "enable_web" {
  description = "Enable web target group and routing"
  type        = bool
  default     = false
}

variable "web_port" {
  description = "Port exposed by the web container"
  type        = number
  default     = 3000
}

variable "web_health_check_path" {
  description = "Health check path for web target group"
  type        = string
  default     = "/"
}

# CloudWatch Alarms
variable "sns_alarm_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms. Required when enable_alarms is true."
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for ALB monitoring. Requires sns_alarm_topic_arn to be set."
  type        = bool
  default     = true
}
