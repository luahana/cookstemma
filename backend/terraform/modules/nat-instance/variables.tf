# NAT Instance Module - Variables

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

variable "vpc_cidr" {
  description = "CIDR block of the VPC (for security group ingress)"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet to place NAT instance in"
  type        = string
}

variable "private_route_table_id" {
  description = "ID of the private route table to add NAT route to"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for NAT instance"
  type        = string
  default     = "t3.nano"
}
