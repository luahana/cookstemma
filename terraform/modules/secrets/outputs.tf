output "database_secret_arn" {
  description = "ARN of the database secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt.arn
}

output "oauth_secret_arn" {
  description = "ARN of the OAuth secret"
  value       = aws_secretsmanager_secret.oauth.arn
}

output "encryption_secret_arn" {
  description = "ARN of the encryption secret"
  value       = aws_secretsmanager_secret.encryption.arn
}

output "firebase_secret_arn" {
  description = "ARN of the Firebase secret"
  value       = aws_secretsmanager_secret.firebase.arn
}

output "s3_secret_arn" {
  description = "ARN of the S3 secret"
  value       = aws_secretsmanager_secret.s3.arn
}

output "all_secret_arns" {
  description = "List of all secret ARNs"
  value = [
    aws_secretsmanager_secret.database.arn,
    aws_secretsmanager_secret.jwt.arn,
    aws_secretsmanager_secret.oauth.arn,
    aws_secretsmanager_secret.encryption.arn,
    aws_secretsmanager_secret.firebase.arn,
    aws_secretsmanager_secret.s3.arn
  ]
}
