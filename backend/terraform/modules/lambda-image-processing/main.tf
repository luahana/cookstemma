# =============================================================================
# LAMBDA IMAGE PROCESSING MODULE
# Generates image variants using SQS for reliable, scalable processing
# Architecture: S3 upload → EventBridge → Orchestrator Lambda → SQS → Processor Lambda
# =============================================================================

locals {
  function_name          = "${var.project_name}-${var.environment}-image-processor"
  orchestrator_name      = "${var.project_name}-${var.environment}-image-orchestrator"
  log_group              = "/aws/lambda/${local.function_name}"
  orchestrator_log_group = "/aws/lambda/${local.orchestrator_name}"
}

# ECR repository is created in shared terraform and passed via var.ecr_repository_url

# -----------------------------------------------------------------------------
# SQS QUEUES
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "image_processing_dlq" {
  name                      = "${var.project_name}-${var.environment}-image-processing-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processing-dlq"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sqs_queue" "image_processing" {
  name                       = "${var.project_name}-${var.environment}-image-processing-queue"
  visibility_timeout_seconds = 90 # Slightly longer than Lambda timeout (60s)
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 20 # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processing-queue"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR LAMBDA
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-image-processor-role"

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
    Name        = "${var.project_name}-${var.environment}-image-processor-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 access policy
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_name}-${var.environment}-image-processor-s3-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arn
      }
    ]
  })
}

# SQS access policy
resource "aws_iam_role_policy" "sqs_access" {
  name = "${var.project_name}-${var.environment}-image-processor-sqs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.image_processing.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.image_processing.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUPS
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "processor" {
  name              = local.log_group
  retention_in_days = 14

  tags = {
    Name        = local.log_group
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "orchestrator" {
  name              = local.orchestrator_log_group
  retention_in_days = 14

  tags = {
    Name        = local.orchestrator_log_group
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# LAMBDA FUNCTIONS
# -----------------------------------------------------------------------------

# Image Processor - handles individual variant generation (triggered by SQS)
resource "aws_lambda_function" "processor" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:${var.environment}-latest"

  memory_size = var.memory_size
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment {
    variables = {
      ENVIRONMENT = var.environment
      S3_BUCKET   = var.s3_bucket_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.processor,
    aws_iam_role_policy_attachment.lambda_basic
  ]

  tags = {
    Name        = local.function_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}

# SQS trigger for processor Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.image_processing.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 1 # Process one variant at a time

  depends_on = [aws_iam_role_policy.sqs_access]
}

# Orchestrator - receives S3 events and sends 8 messages to SQS (one per variant)
resource "aws_lambda_function" "orchestrator" {
  function_name = local.orchestrator_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:${var.environment}-latest"

  # Override the handler for orchestrator
  image_config {
    command = ["handler.orchestrator_handler"]
  }

  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
      S3_BUCKET   = var.s3_bucket_name
      SQS_QUEUE_URL = aws_sqs_queue.image_processing.url
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.orchestrator,
    aws_iam_role_policy_attachment.lambda_basic
  ]

  tags = {
    Name        = local.orchestrator_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}

# Permission for EventBridge to invoke orchestrator Lambda
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orchestrator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.image_upload.arn
}

# -----------------------------------------------------------------------------
# S3 EVENT NOTIFICATION TO EVENTBRIDGE
# Triggers processing when images are uploaded
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "image_uploads" {
  bucket      = var.s3_bucket_name
  eventbridge = true
}

# EventBridge rule to capture S3 object created events
resource "aws_cloudwatch_event_rule" "image_upload" {
  name        = "${var.project_name}-${var.environment}-image-upload"
  description = "Trigger image processing on S3 upload"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.s3_bucket_name]
      }
      object = {
        key = [
          { prefix = "cover/" },
          { prefix = "step/" },
          { prefix = "log_post/" },
          { prefix = "profile/" }
        ]
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-upload"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# EventBridge target - Orchestrator Lambda
resource "aws_cloudwatch_event_target" "orchestrator" {
  rule      = aws_cloudwatch_event_rule.image_upload.name
  target_id = "ImageProcessingOrchestrator"
  arn       = aws_lambda_function.orchestrator.arn

  input_transformer {
    input_paths = {
      bucket    = "$.detail.bucket.name"
      key       = "$.detail.object.key"
      requestId = "$.id"
    }
    input_template = <<EOF
{
  "bucket": <bucket>,
  "key": <key>,
  "request_id": <requestId>
}
EOF
  }
}
