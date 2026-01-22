# =============================================================================
# CLOUDWATCH ALARMS FOR APPLICATION LOAD BALANCER
# Critical alarms for ALB health, performance, and availability
# Cost: 5 alarms × $0.10 = $0.50/month
# =============================================================================

locals {
  create_alarms          = var.enable_alarms
  alb_name               = aws_lb.main.name
  alb_arn_suffix         = aws_lb.main.arn_suffix
  backend_tg_arn_suffix  = aws_lb_target_group.blue.arn_suffix
  web_tg_arn_suffix      = var.enable_web ? aws_lb_target_group.web[0].arn_suffix : ""
}

# =============================================================================
# HTTP ERROR ALARMS
# =============================================================================

# Alarm 1: High 5xx Errors (> 10 errors in 5 minutes)
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  alarm_description   = <<-EOT
    ALB is returning more than 10 5xx errors in 5 minutes.

    Potential causes:
    - Backend ECS tasks are failing or not responding
    - Application errors in Spring Boot backend
    - Database connection issues
    - Lambda function errors (if using Lambda integration)

    Investigation steps:
    1. Check ECS task health and logs in CloudWatch
    2. Check ALB target health status
    3. Review backend application logs for exceptions
    4. Check RDS connection metrics

    Remediation:
    - Fix application errors causing 5xx responses
    - Restart failing ECS tasks if crashed
    - Scale up ECS tasks if overloaded
    - Check database connectivity
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-5xx-errors"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}

# Alarm 2: High 4xx Errors (> 100 errors in 5 minutes)
resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-4xx-errors"
  alarm_description   = <<-EOT
    ALB is returning more than 100 4xx errors in 5 minutes.

    Potential causes:
    - Invalid client requests (malformed JSON, missing headers)
    - Authentication/authorization failures
    - Rate limiting triggered
    - Possible DDoS or bot attack

    Investigation steps:
    1. Check ALB access logs for request patterns
    2. Review application logs for authentication failures
    3. Check client request patterns (user agents, IPs)
    4. Look for unusual traffic spikes

    Remediation:
    - If legitimate traffic: Fix client-side validation issues
    - If attack: Enable AWS WAF rules to block malicious requests
    - Review rate limiting configuration
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-4xx-errors"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# =============================================================================
# PERFORMANCE ALARMS
# =============================================================================

# Alarm 3: High Target Response Time (> 2 seconds P95)
resource "aws_cloudwatch_metric_alarm" "target_response_time_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-response-time-high"
  alarm_description   = <<-EOT
    ALB target response time (P95) is above 2 seconds.

    Potential causes:
    - Backend application performance issues
    - Database query slowness
    - High CPU/memory usage on ECS tasks
    - External API call latency (Firebase, Gemini)

    Investigation steps:
    1. Check ECS CPU/Memory utilization metrics
    2. Review RDS Performance Insights for slow queries
    3. Check application logs for slow endpoints
    4. Review APM traces if available

    Remediation:
    - Optimize slow database queries
    - Add database indexes
    - Scale up ECS tasks (horizontal scaling)
    - Increase ECS task CPU/memory (vertical scaling)
    - Cache frequently accessed data
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300 # 5 minutes
  extended_statistic  = "p95"
  threshold           = 2 # 2 seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-response-time-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# =============================================================================
# HEALTH ALARMS
# =============================================================================

# Alarm 4: Unhealthy Target Count (> 0 unhealthy targets)
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-targets"
  alarm_description   = <<-EOT
    ALB has unhealthy targets (ECS tasks failing health checks).

    Potential causes:
    - ECS tasks crashed or not starting properly
    - Application failing to respond to health check endpoint
    - Health check endpoint returning non-200 status
    - Network connectivity issues

    Investigation steps:
    1. Check ECS task status and logs
    2. Test health check endpoint manually (${var.health_check_path})
    3. Review task startup logs for errors
    4. Check security group rules

    Remediation:
    - Restart failed ECS tasks
    - Fix application errors preventing startup
    - Adjust health check configuration if too aggressive
    - Check database connectivity for backend tasks
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60 # 1 minute (faster detection)
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
    TargetGroup  = local.backend_tg_arn_suffix
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-unhealthy-targets"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}

# Alarm 5: Target Connection Errors (> 5 errors in 5 minutes)
resource "aws_cloudwatch_metric_alarm" "target_connection_errors" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-connection-errors"
  alarm_description   = <<-EOT
    ALB is experiencing target connection errors (> 5 in 5 minutes).

    Potential causes:
    - ECS tasks are not listening on the correct port
    - Security group rules blocking ALB to ECS traffic
    - ECS tasks running out of resources (CPU/memory)
    - Network configuration issues

    Investigation steps:
    1. Check ECS task security group rules
    2. Verify container port mapping (${var.container_port})
    3. Check ECS task resource utilization
    4. Review ECS task network configuration

    Remediation:
    - Fix security group rules to allow ALB traffic
    - Verify container port configuration
    - Scale up ECS tasks if resource constrained
    - Check VPC network ACLs
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetConnectionErrorCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-connection-errors"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}
