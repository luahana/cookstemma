# =============================================================================
# CLOUDWATCH ALARMS FOR ECS WEB SERVICE (Next.js)
# Essential alarms for web frontend health and availability
# Cost: 4 alarms × $0.10 = $0.40/month
# =============================================================================

locals {
  create_alarms = var.enable_alarms
  cluster_name  = aws_ecs_cluster.web.name
  service_name  = aws_ecs_service.web.name
}

# =============================================================================
# RESOURCE UTILIZATION ALARMS
# =============================================================================

# Alarm 1: High CPU Utilization (> 80% for 10 minutes)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-web-cpu-high"
  alarm_description   = <<-EOT
    ECS web service (Next.js) CPU utilization is above 80% for 10 minutes.

    Current configuration:
    - Task CPU: ${var.task_cpu} (${var.task_cpu / 1024} vCPU)
    - Desired count: ${var.desired_count}

    Potential causes:
    - High traffic load (many concurrent users)
    - Inefficient React rendering
    - Server-side rendering (SSR) overhead
    - API data fetching issues

    Investigation steps:
    1. Check request rate in ALB metrics
    2. Review Next.js application logs
    3. Check if SSR is causing performance issues
    4. Profile Node.js CPU usage

    Remediation:
    - Scale horizontally: Increase desired_count
    - Scale vertically: Increase task_cpu (e.g., 256 → 512)
    - Optimize React components (use React.memo, useMemo)
    - Consider static generation (SSG) over SSR where possible
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-web-cpu-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 2: High Memory Utilization (> 90% for 5 minutes)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-web-memory-high"
  alarm_description   = <<-EOT
    ECS web service (Next.js) memory utilization is above 90% for 5 minutes.

    Current configuration:
    - Task memory: ${var.task_memory} MB

    Potential causes:
    - Memory leaks in React components
    - Too many cached pages in Next.js
    - Large bundle sizes
    - Node.js memory management issues

    Investigation steps:
    1. Check Node.js heap usage
    2. Review Next.js build output for large bundles
    3. Analyze memory usage patterns
    4. Check for memory leaks with profiler

    Remediation:
    - Scale vertically: Increase task_memory (e.g., 512 → 1024)
    - Fix memory leaks in React components
    - Optimize Next.js bundle sizes
    - Configure Next.js cache limits
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 90
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-web-memory-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# =============================================================================
# SERVICE HEALTH ALARMS
# =============================================================================

# Alarm 3: Running Task Count Below Desired
resource "aws_cloudwatch_metric_alarm" "task_count_low" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-web-task-count-low"
  alarm_description   = <<-EOT
    ECS web service running task count is below desired count (${var.desired_count}).

    This means one or more Next.js tasks have stopped/crashed.

    Potential causes:
    - Next.js application crashed
    - Task failed health checks
    - Out of memory (OOM) kill
    - Deployment in progress

    Investigation steps:
    1. Check ECS service events for task stop reasons
    2. Review Next.js logs in CloudWatch
    3. Check if task was OOM killed
    4. Verify ALB health check endpoint (/)

    Remediation:
    - Fix Next.js errors causing crashes
    - Increase memory if OOM killed
    - Check health check endpoint responds with 200/307
  EOT
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60 # 1 minute for faster detection
  statistic           = "Average"
  threshold           = var.desired_count
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-web-task-count-low"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}

# Alarm 4: Service Not Running (No running tasks for 2 minutes)
resource "aws_cloudwatch_metric_alarm" "service_down" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-web-service-down"
  alarm_description   = <<-EOT
    ECS web service has NO running tasks for 2 minutes.

    This is a CRITICAL alarm - the website is completely down!

    Potential causes:
    - All Next.js tasks crashed
    - Service manually stopped
    - Critical infrastructure failure

    Investigation steps:
    1. Check ECS service status immediately
    2. Review recent service events
    3. Check Next.js startup logs

    Remediation:
    - Manually start service if stopped
    - Fix critical errors preventing Next.js from starting
    - Rollback to previous working image if deployment issue
  EOT
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-web-service-down"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}
