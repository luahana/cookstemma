# =============================================================================
# CLOUDFRONT CDN MODULE
# CDN for image delivery with automatic WebP selection via Lambda@Edge
# =============================================================================

locals {
  s3_origin_id = "${var.project_name}-${var.environment}-s3-origin"
}

# -----------------------------------------------------------------------------
# ORIGIN ACCESS CONTROL (OAC) for S3
# Replaces legacy Origin Access Identity (OAI)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for S3 bucket access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# S3 BUCKET POLICY FOR CLOUDFRONT ACCESS
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# LAMBDA@EDGE FOR WEBP SELECTION (Optional)
# Must be deployed in us-east-1 for Lambda@Edge
# -----------------------------------------------------------------------------
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "archive_file" "webp_selector" {
  count       = var.enable_webp_selector ? 1 : 0
  type        = "zip"
  source_dir  = var.lambda_code_path
  output_path = "${path.module}/webp-selector.zip"
}

resource "aws_iam_role" "lambda_edge" {
  count = var.enable_webp_selector ? 1 : 0
  name  = "${var.project_name}-${var.environment}-webp-selector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-webp-selector-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  count      = var.enable_webp_selector ? 1 : 0
  role       = aws_iam_role.lambda_edge[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "webp_selector" {
  count         = var.enable_webp_selector ? 1 : 0
  provider      = aws.us_east_1
  filename      = data.archive_file.webp_selector[0].output_path
  function_name = "${var.project_name}-${var.environment}-webp-selector"
  role          = aws_iam_role.lambda_edge[0].arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  publish       = true # Required for Lambda@Edge

  source_code_hash = data.archive_file.webp_selector[0].output_base64sha256

  tags = {
    Name        = "${var.project_name}-${var.environment}-webp-selector"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# CLOUDFRONT DISTRIBUTION
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} image CDN"
  default_root_object = ""
  price_class         = var.price_class

  # Custom domain aliases (optional)
  aliases = var.aliases

  # S3 Origin
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Default cache behavior for images
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Accept"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1 day
    max_ttl                = 31536000 # 1 year
    compress               = true

    # Lambda@Edge for WebP selection (origin-request)
    dynamic "lambda_function_association" {
      for_each = var.enable_webp_selector ? [1] : []
      content {
        event_type   = "origin-request"
        lambda_arn   = aws_lambda_function.webp_selector[0].qualified_arn
        include_body = false
      }
    }
  }

  # Cache behavior for variants (longer cache)
  ordered_cache_behavior {
    path_pattern     = "/*/variants/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Accept"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 86400    # 1 day minimum
    default_ttl            = 2592000  # 30 days
    max_ttl                = 31536000 # 1 year
    compress               = true

    # Lambda@Edge for WebP selection
    dynamic "lambda_function_association" {
      for_each = var.enable_webp_selector ? [1] : []
      content {
        event_type   = "origin-request"
        lambda_arn   = aws_lambda_function.webp_selector[0].qualified_arn
        include_body = false
      }
    }
  }

  # Geo restrictions (none)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == null
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = var.certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.certificate_arn != null ? "TLSv1.2_2021" : null
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cdn"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# CLOUDFRONT RESPONSE HEADERS POLICY
# Add cache headers and CORS
# -----------------------------------------------------------------------------
resource "aws_cloudfront_response_headers_policy" "images" {
  name    = "${var.project_name}-${var.environment}-image-headers"
  comment = "Headers for image responses"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD"]
    }

    access_control_allow_origins {
      items = ["*"]
    }

    origin_override = true
  }

  security_headers_config {
    content_type_options {
      override = true
    }
  }

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=31536000, immutable"
      override = false
    }
  }
}
