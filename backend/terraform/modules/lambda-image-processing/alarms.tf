# =============================================================================
# CLOUDWATCH ALARMS FOR IMAGE PROCESSING LAMBDA
# Critical alarms for image processing Lambda functions and SQS queues
# Cost: 5 alarms × $0.10 = $0.50/month
# =============================================================================

locals {
  create_alarms = var.enable_alarms
}

# =============================================================================
# LAMBDA PROCESSOR ALARMS
# =============================================================================

# Alarm 1: High Error Rate (> 5 errors in 5 minutes)
resource "aws_cloudwatch_metric_alarm" "processor_errors" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-image-processor-errors"
  alarm_description   = <<-EOT
    Image processor Lambda is experiencing high error rate (> 5 errors in 5 minutes).

    Potential causes:
    - Invalid image formats uploaded
    - S3 bucket access issues
    - Image processing library errors (Pillow)
    - Memory exhaustion (large images)
    - Timeout issues

    Investigation steps:
    1. Check Lambda logs in CloudWatch: ${local.log_group}
    2. Review DLQ messages for failed processing details
    3. Check S3 bucket permissions
    4. Verify image formats being uploaded

    Remediation:
    - Add better input validation for image formats
    - Increase Lambda memory if processing large images
    - Fix S3 access permissions
    - Handle edge cases in image processing code
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.function_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processor-errors"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 2: Long Duration (> 50 seconds, near 60s timeout)
resource "aws_cloudwatch_metric_alarm" "processor_duration_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-image-processor-duration-high"
  alarm_description   = <<-EOT
    Image processor Lambda duration is approaching timeout (> 50 seconds, timeout is ${var.timeout}s).

    Potential causes:
    - Very large images being processed
    - Inefficient image processing code
    - Too many variant sizes being generated
    - S3 upload/download latency

    Investigation steps:
    1. Check Lambda duration metrics by percentile (p50, p95, p99)
    2. Review image sizes being processed
    3. Profile image processing performance
    4. Check S3 transfer speeds

    Remediation:
    - Optimize image processing pipeline
    - Reduce number of variant sizes if possible
    - Increase Lambda timeout if needed (max 900s)
    - Consider processing very large images separately
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 50000 # 50 seconds in milliseconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.function_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processor-duration-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 3: Lambda Throttles (> 0 throttles)
resource "aws_cloudwatch_metric_alarm" "processor_throttles" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-image-processor-throttles"
  alarm_description   = <<-EOT
    Image processor Lambda is being throttled (concurrent execution limit reached).

    Current configuration:
    - Reserved concurrent executions: ${var.reserved_concurrent_executions}

    Potential causes:
    - Burst of image uploads exceeding concurrency limit
    - Account-level Lambda concurrency limit reached
    - Too low reserved concurrency setting

    Investigation steps:
    1. Check ConcurrentExecutions metric
    2. Review S3 upload patterns
    3. Check account-level Lambda quotas
    4. Verify reserved concurrency setting

    Remediation:
    - Increase reserved_concurrent_executions if needed
    - Request account limit increase if at account quota
    - Add rate limiting on image uploads
    - Consider using SQS to buffer upload events
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.function_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processor-throttles"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# =============================================================================
# SQS QUEUE ALARMS
# =============================================================================

# Alarm 4: Dead Letter Queue Messages (> 0 messages)
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-image-processing-dlq-messages"
  alarm_description   = <<-EOT
    Image processing DLQ has messages (images failed processing after retries).

    This is CRITICAL - images are failing to process!

    Potential causes:
    - Persistent errors in image processing
    - Invalid/corrupted image files
    - S3 bucket issues
    - Code bugs

    Investigation steps:
    1. Check DLQ messages for error details
    2. Review Lambda error logs
    3. Manually inspect failed images in S3
    4. Check if specific image format causing issues

    Remediation:
    - Fix underlying error causing failures
    - Manually reprocess valid images from DLQ
    - Add better error handling for edge cases
    - Consider adding image validation before processing
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.image_processing_dlq.name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processing-dlq-messages"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}

# Alarm 5: High Concurrent Executions (> 80% of reserved, only if reserved > 0)
resource "aws_cloudwatch_metric_alarm" "concurrent_executions_high" {
  count = local.create_alarms && var.reserved_concurrent_executions > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-image-processor-concurrency-high"
  alarm_description   = <<-EOT
    Image processor Lambda concurrent executions approaching limit.

    Current configuration:
    - Reserved concurrent executions: ${var.reserved_concurrent_executions}
    - Alarm threshold: ${var.reserved_concurrent_executions * 0.8} (80%)

    This is a warning that capacity is running out.

    Investigation steps:
    1. Check image upload rate trends
    2. Review Lambda duration to see if processing is slow
    3. Check if there's a backlog in SQS queue

    Remediation:
    - Increase reserved_concurrent_executions
    - Optimize Lambda processing time
    - Add rate limiting on uploads if needed
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60 # 1 minute
  statistic           = "Maximum"
  threshold           = var.reserved_concurrent_executions * 0.8 # 80% of reserved
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.function_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-image-processor-concurrency-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}
