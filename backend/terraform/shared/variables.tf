variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "cookstemma"
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "luahana/cookstemma"
}
