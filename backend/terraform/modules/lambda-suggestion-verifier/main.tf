# =============================================================================
# LAMBDA SUGGESTION VERIFIER MODULE
# Validates and processes user-suggested foods/ingredients using AI
# =============================================================================

locals {
  function_name = "${var.project_name}-${var.environment}-suggestion-verifier"
  log_group     = "/aws/lambda/${local.function_name}"
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR LAMBDA
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-suggestion-verifier-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-suggestion-verifier-lambda-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Basic Lambda execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-${var.environment}-suggestion-verifier-secrets-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.database_secret_arn,
          var.gemini_secret_arn
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SECURITY GROUP FOR LAMBDA
# Either create new or use existing (to break circular dependencies)
# -----------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  count = var.use_existing_security_group ? 0 : 1

  name        = "${var.project_name}-${var.environment}-suggestion-verifier-lambda-sg"
  description = "Security group for suggestion verifier Lambda"
  vpc_id      = var.vpc_id

  # Outbound: Allow all (needed for RDS, Secrets Manager, Gemini API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-suggestion-verifier-lambda-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

locals {
  lambda_security_group_id = var.use_existing_security_group ? var.existing_security_group_id : aws_security_group.lambda[0].id
}

# -----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.log_group
  retention_in_days = 14

  tags = {
    Name        = local.log_group
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# LAMBDA FUNCTION (Container-based)
# ECR repository is created in shared terraform and passed via var.ecr_repository_url
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "suggestion_verifier" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:${var.environment}-latest"
  architectures = [var.architecture]  # arm64 = Graviton, x86_64 = Intel

  memory_size = var.memory_size
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [local.lambda_security_group_id]
  }

  environment {
    variables = {
      DATABASE_SECRET_ARN = var.database_secret_arn
      GEMINI_SECRET_ARN   = var.gemini_secret_arn
      ENVIRONMENT         = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc
  ]

  tags = {
    Name        = local.function_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Ignore changes to image_uri - managed by CI/CD
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# -----------------------------------------------------------------------------
# EVENTBRIDGE SCHEDULED RULE (Daily Processing)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "${var.project_name}-${var.environment}-suggestion-verifier-daily"
  description         = "Trigger suggestion verifier Lambda daily"
  schedule_expression = var.schedule_expression

  tags = {
    Name        = "${var.project_name}-${var.environment}-suggestion-verifier-daily"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "SuggestionVerifierLambda"
  arn       = aws_lambda_function.suggestion_verifier.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.suggestion_verifier.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule.arn
}
