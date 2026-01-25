# =============================================================================
# CLOUDWATCH ALARMS FOR KEYWORD GENERATOR LAMBDA
# Critical alarms for AI-powered keyword generation
# Cost: 5 alarms × $0.10 = $0.50/month
# =============================================================================

locals {
  create_alarms = var.enable_alarms
}

# =============================================================================
# LAMBDA FUNCTION ALARMS
# =============================================================================

# Alarm 1: High Error Rate (> 5 errors in 5 minutes)
resource "aws_cloudwatch_metric_alarm" "errors" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-keyword-generator-errors"
  alarm_description   = <<-EOT
    Keyword generator Lambda is experiencing high error rate (> 5 errors in 5 minutes).

    Potential causes:
    - Gemini API errors or rate limits
    - Database connection issues
    - Invalid food data
    - Code bugs in keyword generation logic

    Investigation steps:
    1. Check Lambda logs in CloudWatch: ${local.log_group}
    2. Review Gemini API response errors
    3. Check database connectivity
    4. Verify food data format (name, description JSONB)

    Remediation:
    - Handle Gemini API errors gracefully
    - Add retry logic with exponential backoff
    - Fix database query issues
    - Add input validation for food data
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
    Name        = "${var.project_name}-${var.environment}-keyword-generator-errors"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 2: Long Duration (> 540 seconds, near 600s timeout)
resource "aws_cloudwatch_metric_alarm" "duration_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-keyword-generator-duration-high"
  alarm_description   = <<-EOT
    Keyword generator Lambda duration is approaching timeout (> 540 seconds, timeout is ${var.timeout}s).

    Potential causes:
    - Processing too many foods in one batch
    - Slow Gemini API responses (generating 20 languages)
    - Database query slowness
    - Network latency issues

    Investigation steps:
    1. Check how many foods are processed per invocation
    2. Review Gemini API response times
    3. Check RDS Performance Insights for slow queries
    4. Profile Lambda execution time

    Remediation:
    - Reduce batch size of foods processed (currently 20)
    - Optimize Gemini API calls
    - Add indexes to database tables
    - Increase Lambda timeout if needed (max 900s)
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 540000 # 540 seconds in milliseconds (90% of timeout)
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.function_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-keyword-generator-duration-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 3: Lambda Throttles (> 0 throttles)
resource "aws_cloudwatch_metric_alarm" "throttles" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-keyword-generator-throttles"
  alarm_description   = <<-EOT
    Keyword generator Lambda is being throttled (concurrent execution limit reached).

    Current configuration:
    - Reserved concurrent executions: ${var.reserved_concurrent_executions}
    - Schedule: ${var.schedule_expression}

    Potential causes:
    - Multiple scheduled invocations overlapping
    - Account-level Lambda concurrency limit reached
    - Too low reserved concurrency setting

    Investigation steps:
    1. Check if previous invocations are still running
    2. Review Lambda duration to see if taking too long
    3. Check account-level Lambda quotas

    Remediation:
    - Increase reserved_concurrent_executions if needed
    - Optimize Lambda to complete faster
    - Adjust schedule expression to run less frequently
    - Request account limit increase if at quota
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
    Name        = "${var.project_name}-${var.environment}-keyword-generator-throttles"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 4: No Invocations (Lambda not running for 24 hours)
resource "aws_cloudwatch_metric_alarm" "no_invocations" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-keyword-generator-no-invocations"
  alarm_description   = <<-EOT
    Keyword generator Lambda has not been invoked in 24 hours.

    This may indicate the scheduled EventBridge rule is disabled or broken.

    Potential causes:
    - EventBridge rule disabled
    - EventBridge rule misconfigured
    - Lambda function deleted or renamed
    - IAM permissions issue

    Investigation steps:
    1. Check EventBridge rule status
    2. Verify rule target configuration
    3. Check Lambda function exists and is enabled
    4. Review IAM permissions for EventBridge to invoke Lambda

    Remediation:
    - Enable EventBridge rule if disabled
    - Fix rule target configuration
    - Update IAM permissions if needed
  EOT
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = 86400 # 24 hours
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "breaching" # Treat missing data as alarm

  dimensions = {
    FunctionName = local.function_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-keyword-generator-no-invocations"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 5: High Concurrent Executions (> 80% of reserved, only if reserved > 0)
resource "aws_cloudwatch_metric_alarm" "concurrent_executions_high" {
  count = local.create_alarms && var.reserved_concurrent_executions > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-keyword-generator-concurrency-high"
  alarm_description   = <<-EOT
    Keyword generator Lambda concurrent executions approaching limit.

    Current configuration:
    - Reserved concurrent executions: ${var.reserved_concurrent_executions}
    - Alarm threshold: ${var.reserved_concurrent_executions * 0.8} (80%)

    This is a warning that capacity is running out.

    Investigation steps:
    1. Check if previous invocations are taking too long
    2. Review Lambda duration metrics
    3. Check if schedule frequency is too high

    Remediation:
    - Increase reserved_concurrent_executions
    - Optimize Lambda processing time
    - Adjust schedule expression if too frequent
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
    Name        = "${var.project_name}-${var.environment}-keyword-generator-concurrency-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}
