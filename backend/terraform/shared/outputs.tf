output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "web_ecr_repository_url" {
  description = "URL of the web ECR repository"
  value       = aws_ecr_repository.web.repository_url
}

output "web_ecr_repository_arn" {
  description = "ARN of the web ECR repository"
  value       = aws_ecr_repository.web.arn
}

output "web_ecr_repository_name" {
  description = "Name of the web ECR repository"
  value       = aws_ecr_repository.web.name
}

output "translator_ecr_repository_url" {
  description = "URL of the translator ECR repository"
  value       = aws_ecr_repository.translator.repository_url
}

output "translator_ecr_repository_arn" {
  description = "ARN of the translator ECR repository"
  value       = aws_ecr_repository.translator.arn
}

output "translator_ecr_repository_name" {
  description = "Name of the translator ECR repository"
  value       = aws_ecr_repository.translator.name
}

output "image_processor_ecr_repository_url" {
  description = "URL of the image processor ECR repository"
  value       = aws_ecr_repository.image_processor.repository_url
}

output "image_processor_ecr_repository_arn" {
  description = "ARN of the image processor ECR repository"
  value       = aws_ecr_repository.image_processor.arn
}

output "image_processor_ecr_repository_name" {
  description = "Name of the image processor ECR repository"
  value       = aws_ecr_repository.image_processor.name
}
