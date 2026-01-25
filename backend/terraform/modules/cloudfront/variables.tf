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

variable "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "aliases" {
  description = "Custom domain aliases for CloudFront (optional)"
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain (required if aliases provided)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe only (cheapest)
}

variable "enable_webp_selector" {
  description = "Enable Lambda@Edge for automatic WebP selection"
  type        = bool
  default     = true
}

variable "lambda_code_path" {
  description = "Path to Lambda@Edge code directory"
  type        = string
  default     = "../../../lambda/webp-selector"
}
