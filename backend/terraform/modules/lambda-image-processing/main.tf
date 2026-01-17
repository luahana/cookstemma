# =============================================================================
# LAMBDA IMAGE PROCESSING MODULE
# Generates image variants using Step Functions for parallel processing
# =============================================================================

locals {
  function_name          = "${var.project_name}-${var.environment}-image-processor"
  orchestrator_name      = "${var.project_name}-${var.environment}-image-orchestrator"
  log_group              = "/aws/lambda/${local.function_name}"
  orchestrator_log_group = "/aws/lambda/${local.orchestrator_name}"
}

# -----------------------------------------------------------------------------
# ECR REPOSITORY FOR LAMBDA CONTAINER
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "image_processor" {
  name                 = "${var.project_name}-${var.environment}-image-processor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processor-ecr"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "image_processor" {
  repository = aws_ecr_repository.image_processor.name

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

# Image Processor - handles individual variant generation
resource "aws_lambda_function" "processor" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.image_processor.repository_url}:latest"

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

# Orchestrator - receives S3 events and triggers Step Functions
resource "aws_lambda_function" "orchestrator" {
  function_name = local.orchestrator_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.image_processor.repository_url}:latest"

  # Override the handler for orchestrator
  image_config {
    command = ["handler.orchestrator_handler"]
  }

  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      S3_BUCKET         = var.s3_bucket_name
      STATE_MACHINE_ARN = aws_sfn_state_machine.image_processing.arn
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

# Permission for orchestrator to start Step Functions
resource "aws_iam_role_policy" "stepfunctions_start" {
  name = "${var.project_name}-${var.environment}-orchestrator-sfn-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = aws_sfn_state_machine.image_processing.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# STEP FUNCTIONS STATE MACHINE
# Parallel processing of image variants
# -----------------------------------------------------------------------------
resource "aws_iam_role" "stepfunctions" {
  name = "${var.project_name}-${var.environment}-image-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-sfn-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "stepfunctions_lambda" {
  name = "${var.project_name}-${var.environment}-image-sfn-lambda-policy"
  role = aws_iam_role.stepfunctions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.processor.arn
      }
    ]
  })
}

resource "aws_sfn_state_machine" "image_processing" {
  name     = "${var.project_name}-${var.environment}-image-processing"
  role_arn = aws_iam_role.stepfunctions.arn

  definition = jsonencode({
    Comment = "Parallel image variant processing"
    StartAt = "ProcessVariants"
    States = {
      ProcessVariants = {
        Type = "Parallel"
        Branches = [
          # JPEG variants
          {
            StartAt = "LARGE_1200_JPEG"
            States = {
              "LARGE_1200_JPEG" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "LARGE_1200"
                  "format"      = "JPEG"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          {
            StartAt = "MEDIUM_800_JPEG"
            States = {
              "MEDIUM_800_JPEG" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "MEDIUM_800"
                  "format"      = "JPEG"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          {
            StartAt = "THUMB_400_JPEG"
            States = {
              "THUMB_400_JPEG" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "THUMB_400"
                  "format"      = "JPEG"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          {
            StartAt = "THUMB_200_JPEG"
            States = {
              "THUMB_200_JPEG" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "THUMB_200"
                  "format"      = "JPEG"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          # WebP variants
          {
            StartAt = "LARGE_1200_WEBP"
            States = {
              "LARGE_1200_WEBP" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "LARGE_1200"
                  "format"      = "WEBP"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          {
            StartAt = "MEDIUM_800_WEBP"
            States = {
              "MEDIUM_800_WEBP" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "MEDIUM_800"
                  "format"      = "WEBP"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          {
            StartAt = "THUMB_400_WEBP"
            States = {
              "THUMB_400_WEBP" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "THUMB_400"
                  "format"      = "WEBP"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          },
          {
            StartAt = "THUMB_200_WEBP"
            States = {
              "THUMB_200_WEBP" = {
                Type     = "Task"
                Resource = aws_lambda_function.processor.arn
                Parameters = {
                  "bucket.$"    = "$.bucket"
                  "key.$"       = "$.key"
                  "variant"     = "THUMB_200"
                  "format"      = "WEBP"
                  "public_id.$" = "$.public_id"
                  "image_id.$"  = "$.image_id"
                }
                End = true
              }
            }
          }
        ]
        End = true
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processing"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
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
        key = [{
          prefix = "images/"
        }]
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

# EventBridge target - Step Functions
resource "aws_cloudwatch_event_target" "stepfunctions" {
  rule      = aws_cloudwatch_event_rule.image_upload.name
  target_id = "ImageProcessingStateMachine"
  arn       = aws_sfn_state_machine.image_processing.arn
  role_arn  = aws_iam_role.eventbridge_sfn.arn

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
  "public_id": <requestId>
}
EOF
  }
}

# IAM role for EventBridge to invoke Step Functions
resource "aws_iam_role" "eventbridge_sfn" {
  name = "${var.project_name}-${var.environment}-eventbridge-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-eventbridge-sfn-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "eventbridge_sfn" {
  name = "${var.project_name}-${var.environment}-eventbridge-sfn-policy"
  role = aws_iam_role.eventbridge_sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = aws_sfn_state_machine.image_processing.arn
      }
    ]
  })
}
