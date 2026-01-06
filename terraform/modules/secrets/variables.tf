variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Database variables
variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

# JWT variables
variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

# OAuth variables
variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

# Encryption variables
variable "encryption_key" {
  description = "Encryption key"
  type        = string
  sensitive   = true
}

# Firebase variables
variable "firebase_credentials" {
  description = "Firebase credentials JSON"
  type        = string
  sensitive   = true
}

# S3 variables
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
}
