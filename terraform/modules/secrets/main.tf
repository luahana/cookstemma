# Secrets Manager Module
# Creates secrets for application configuration

# Database credentials secret
resource "aws_secretsmanager_secret" "database" {
  name        = "${var.project_name}/${var.environment}/database"
  description = "Database credentials for ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-database-secret"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
    url      = "jdbc:postgresql://${var.db_host}:${var.db_port}/${var.db_name}"
  })
}

# JWT secret
resource "aws_secretsmanager_secret" "jwt" {
  name        = "${var.project_name}/${var.environment}/jwt"
  description = "JWT secret key for ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id = aws_secretsmanager_secret.jwt.id
  secret_string = jsonencode({
    secret_key = var.jwt_secret_key
  })
}

# OAuth credentials secret
resource "aws_secretsmanager_secret" "oauth" {
  name        = "${var.project_name}/${var.environment}/oauth"
  description = "OAuth credentials for ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-oauth-secret"
  }
}

resource "aws_secretsmanager_secret_version" "oauth" {
  secret_id = aws_secretsmanager_secret.oauth.id
  secret_string = jsonencode({
    google_client_id     = var.google_client_id
    google_client_secret = var.google_client_secret
  })
}

# Encryption key secret
resource "aws_secretsmanager_secret" "encryption" {
  name        = "${var.project_name}/${var.environment}/encryption"
  description = "Encryption key for ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-encryption-secret"
  }
}

resource "aws_secretsmanager_secret_version" "encryption" {
  secret_id = aws_secretsmanager_secret.encryption.id
  secret_string = jsonencode({
    key = var.encryption_key
  })
}

# Firebase credentials secret
resource "aws_secretsmanager_secret" "firebase" {
  name        = "${var.project_name}/${var.environment}/firebase"
  description = "Firebase credentials for ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-firebase-secret"
  }
}

resource "aws_secretsmanager_secret_version" "firebase" {
  secret_id = aws_secretsmanager_secret.firebase.id
  secret_string = jsonencode({
    credentials = var.firebase_credentials
  })
}

# S3 credentials secret
resource "aws_secretsmanager_secret" "s3" {
  name        = "${var.project_name}/${var.environment}/s3"
  description = "S3 credentials for ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-secret"
  }
}

resource "aws_secretsmanager_secret_version" "s3" {
  secret_id = aws_secretsmanager_secret.s3.id
  secret_string = jsonencode({
    access_key = var.s3_access_key
    secret_key = var.s3_secret_key
    bucket     = var.s3_bucket
    region     = var.s3_region
  })
}
