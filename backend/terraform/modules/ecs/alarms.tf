# =============================================================================
# CLOUDWATCH ALARMS FOR ECS BACKEND SERVICE
# Critical alarms for ECS task health, resource utilization, and availability
# Cost: 8 alarms × $0.10 = $0.80/month
# =============================================================================

locals {
  create_alarms = var.enable_alarms
  cluster_name  = aws_ecs_cluster.main.name
  service_name  = aws_ecs_service.main.name
}

# =============================================================================
# RESOURCE UTILIZATION ALARMS
# =============================================================================

# Alarm 1: High CPU Utilization (> 80% for 10 minutes)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  alarm_description   = <<-EOT
    ECS backend service CPU utilization is above 80% for 10 minutes.

    Current configuration:
    - Task CPU: ${var.task_cpu} (${var.task_cpu / 1024} vCPU)
    - Desired count: ${var.desired_count}

    Potential causes:
    - High traffic load
    - Inefficient application code (CPU-intensive operations)
    - Blocking operations in request handlers
    - Background jobs consuming CPU

    Investigation steps:
    1. Check request rate in ALB metrics
    2. Review application logs for slow endpoints
    3. Check for long-running background jobs
    4. Profile CPU usage with APM tools

    Remediation:
    - Scale horizontally: Increase desired_count
    - Scale vertically: Increase task_cpu (e.g., 512 → 1024)
    - Optimize CPU-intensive code paths
    - Move background jobs to separate workers
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
    Name        = "${var.project_name}-${var.environment}-ecs-cpu-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 2: High Memory Utilization (> 90% for 5 minutes)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  alarm_description   = <<-EOT
    ECS backend service memory utilization is above 90% for 5 minutes.

    Current configuration:
    - Task memory: ${var.task_memory} MB
    - JVM heap configured for this memory limit

    Potential causes:
    - Memory leaks in application code
    - Too many concurrent connections/sessions
    - Large response payloads
    - Inefficient caching
    - JVM heap misconfiguration

    Investigation steps:
    1. Check JVM heap usage via JMX/Actuator
    2. Review memory usage patterns in Container Insights
    3. Analyze heap dumps if OOM occurs
    4. Check for memory leaks with profiler

    Remediation:
    - Scale vertically: Increase task_memory (e.g., 1024 → 2048)
    - Fix memory leaks in application
    - Tune JVM heap settings
    - Optimize caching strategy
    - Review large object allocations
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
    Name        = "${var.project_name}-${var.environment}-ecs-memory-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}

# Alarm 3: CPU Utilization Moderate (> 70% for 15 minutes)
resource "aws_cloudwatch_metric_alarm" "cpu_moderate" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-moderate"
  alarm_description   = <<-EOT
    ECS backend service CPU utilization is above 70% for 15 minutes.

    This is a warning alarm indicating sustained moderate CPU usage.
    Not critical yet, but may require capacity planning.

    Investigation steps:
    1. Review traffic trends
    2. Check if this is normal peak hours
    3. Assess if current capacity is adequate

    Remediation:
    - Consider scaling if trend is increasing
    - Plan capacity for upcoming traffic growth
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cpu-moderate"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 4: Memory Utilization Moderate (> 80% for 10 minutes)
resource "aws_cloudwatch_metric_alarm" "memory_moderate" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-moderate"
  alarm_description   = <<-EOT
    ECS backend service memory utilization is above 80% for 10 minutes.

    This is a warning alarm indicating sustained moderate memory usage.
    Not critical yet, but getting close to limit.

    Investigation steps:
    1. Monitor memory growth trend
    2. Check for gradual memory leaks
    3. Review JVM garbage collection patterns

    Remediation:
    - Monitor closely for increasing trend
    - Consider scaling vertically if approaching 90%
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
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
    Name        = "${var.project_name}-${var.environment}-ecs-memory-moderate"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# =============================================================================
# SERVICE HEALTH ALARMS
# =============================================================================

# Alarm 5: Running Task Count Below Desired
resource "aws_cloudwatch_metric_alarm" "task_count_low" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-task-count-low"
  alarm_description   = <<-EOT
    ECS backend service running task count is below desired count (${var.desired_count}).

    This means one or more tasks have stopped/crashed.

    Potential causes:
    - Task crashed due to application error
    - Task failed health checks
    - Out of memory (OOM) kill
    - Deployment in progress
    - Infrastructure issues

    Investigation steps:
    1. Check ECS service events for task stop reasons
    2. Review task logs in CloudWatch for errors
    3. Check if task was OOM killed
    4. Verify deployment status

    Remediation:
    - Fix application errors causing crashes
    - Increase memory if OOM killed
    - Fix health check endpoint if failing
    - Check ALB target health
  EOT
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60 # 1 minute for faster detection
  statistic           = "Average"
  threshold           = var.desired_count
  treat_missing_data  = "breaching" # Treat missing data as alarm (service might be down)

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-count-low"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}

# Alarm 6: Task Stopped (Monitoring stopped tasks)
resource "aws_cloudwatch_metric_alarm" "task_stopped" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-task-stopped"
  alarm_description   = <<-EOT
    ECS backend tasks are stopping unexpectedly.

    This alarm triggers when tasks stop, which may indicate:
    - Application crashes
    - Health check failures
    - Out of memory errors
    - Infrastructure issues

    Investigation steps:
    1. Check ECS console for stopped task details
    2. Review "Stopped reason" in task history
    3. Check task logs for errors before stop
    4. Verify task resource limits (CPU, memory)

    Remediation:
    - Address root cause based on stop reason
    - Increase resources if needed
    - Fix application bugs
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60 # 1 minute
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
    TaskGroup   = "service:${local.service_name}"
    DesiredStatus = "STOPPED"
  }

  alarm_actions = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-stopped"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 7: Service Deployment Failed
resource "aws_cloudwatch_metric_alarm" "deployment_failed" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-deployment-failed"
  alarm_description   = <<-EOT
    ECS backend service deployment is failing or tasks not reaching healthy state.

    This alarm uses pending task count as a proxy for deployment issues.
    If tasks stay pending for too long, deployment may be stuck.

    Potential causes:
    - New container image crashes on startup
    - Health check endpoint not responding
    - Resource constraints (CPU, memory)
    - Docker pull errors

    Investigation steps:
    1. Check ECS service events
    2. Review new task logs for startup errors
    3. Verify health check endpoint works
    4. Check ECR image availability

    Remediation:
    - Rollback to previous working image
    - Fix startup errors in new image
    - Adjust health check configuration
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "PendingTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-deployment-failed"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 8: Service Not Running (No running tasks for 2 minutes)
resource "aws_cloudwatch_metric_alarm" "service_down" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-service-down"
  alarm_description   = <<-EOT
    ECS backend service has NO running tasks for 2 minutes.

    This is a CRITICAL alarm - the service is completely down!

    Potential causes:
    - All tasks crashed
    - Service manually stopped
    - Account limits reached
    - Critical infrastructure failure

    Investigation steps:
    1. Check ECS service status immediately
    2. Review recent service events
    3. Check account service quotas
    4. Verify VPC/subnet configuration

    Remediation:
    - Manually start service if stopped
    - Address critical errors preventing task start
    - Contact AWS support if infrastructure issue
  EOT
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching" # Treat missing data as critical alarm

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-service-down"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "critical"
  }
}
