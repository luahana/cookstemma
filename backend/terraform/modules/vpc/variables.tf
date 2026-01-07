variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "create_private_subnets" {
  description = "Whether to create private subnets"
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Whether to create NAT gateway (for private subnet internet access)"
  type        = bool
  default     = false
}
