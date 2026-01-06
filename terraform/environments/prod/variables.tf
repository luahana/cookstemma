variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pairing-planet"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "pairing-planet"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

# Database variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "pairingplanet"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# JWT
variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

# OAuth
variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

# Encryption
variable "encryption_key" {
  description = "Encryption key for sensitive data"
  type        = string
  sensitive   = true
}

# Firebase
variable "firebase_credentials" {
  description = "Firebase credentials JSON"
  type        = string
  sensitive   = true
}

# S3
variable "s3_access_key" {
  description = "S3 access key"
  type        = string
}

variable "s3_secret_key" {
  description = "S3 secret key"
  type        = string
  sensitive   = true
}

variable "s3_bucket" {
  description = "S3 bucket name"
  type        = string
}

variable "s3_region" {
  description = "S3 region"
  type        = string
  default     = "ap-northeast-2"
}
