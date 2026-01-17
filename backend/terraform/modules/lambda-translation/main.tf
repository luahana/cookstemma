# =============================================================================
# LAMBDA TRANSLATION MODULE
# Translates user content using OpenAI GPT
# =============================================================================

locals {
  function_name = "${var.project_name}-${var.environment}-translator"
  log_group     = "/aws/lambda/${local.function_name}"
}

# -----------------------------------------------------------------------------
# OPENAI SECRET
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "openai" {
  name        = "${var.project_name}/${var.environment}/openai"
  description = "OpenAI API credentials for translation"

  tags = {
    Name        = "${var.project_name}-${var.environment}-openai-secret"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "openai" {
  secret_id = aws_secretsmanager_secret.openai.id
  secret_string = jsonencode({
    api_key = var.openai_api_key
  })
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR LAMBDA
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-translator-lambda-role"

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
    Name        = "${var.project_name}-${var.environment}-translator-lambda-role"
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
  name = "${var.project_name}-${var.environment}-translator-secrets-policy"
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
          aws_secretsmanager_secret.openai.arn
        ]
      }
    ]
  })
}

# SQS access policy
resource "aws_iam_role_policy" "sqs_access" {
  name = "${var.project_name}-${var.environment}-translator-sqs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.translation_queue.arn
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

  name        = "${var.project_name}-${var.environment}-translator-lambda-sg"
  description = "Security group for translation Lambda"
  vpc_id      = var.vpc_id

  # Outbound: Allow all (needed for RDS, Secrets Manager, OpenAI API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-translator-lambda-sg"
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
# ECR REPOSITORY FOR LAMBDA CONTAINER
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "translator" {
  name                 = "${var.project_name}-${var.environment}-translator"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-translator-ecr"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "translator" {
  repository = aws_ecr_repository.translator.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# -----------------------------------------------------------------------------
# LAMBDA FUNCTION (Container-based)
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "translator" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.translator.repository_url}:latest"

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
      OPENAI_SECRET_ARN   = aws_secretsmanager_secret.openai.arn
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
# SQS QUEUE FOR TRANSLATION EVENTS
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "translation_dlq" {
  name                      = "${var.project_name}-${var.environment}-translation-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "${var.project_name}-${var.environment}-translation-dlq"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sqs_queue" "translation_queue" {
  name                       = "${var.project_name}-${var.environment}-translation-queue"
  visibility_timeout_seconds = 330   # Slightly longer than Lambda timeout
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 20    # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.translation_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-translation-queue"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# SQS trigger for Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.translation_queue.arn
  function_name    = aws_lambda_function.translator.arn
  batch_size       = 1 # Process one at a time for translation

  depends_on = [aws_iam_role_policy.sqs_access]
}

# -----------------------------------------------------------------------------
# EVENTBRIDGE SCHEDULED RULE (Batch Processing)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "translation_schedule" {
  name                = "${var.project_name}-${var.environment}-translation-schedule"
  description         = "Trigger translation Lambda for batch processing"
  schedule_expression = var.schedule_expression

  tags = {
    Name        = "${var.project_name}-${var.environment}-translation-schedule"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "translation_lambda" {
  rule      = aws_cloudwatch_event_rule.translation_schedule.name
  target_id = "TranslationLambda"
  arn       = aws_lambda_function.translator.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.translator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.translation_schedule.arn
}
