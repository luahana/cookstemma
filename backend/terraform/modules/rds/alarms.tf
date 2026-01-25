# =============================================================================
# CLOUDWATCH ALARMS FOR RDS DATABASE MONITORING
# Critical alarms for database health, performance, and capacity
# Cost: 6 alarms × $0.10 = $0.60/month
# =============================================================================

locals {
  create_alarms = var.enable_alarms
  db_identifier = aws_db_instance.main.identifier
}

# =============================================================================
# PERFORMANCE ALARMS
# =============================================================================

# Alarm 1: High CPU Utilization (> 80% for 10 minutes)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  alarm_description   = <<-EOT
    RDS CPU utilization is above 80% for 10 minutes.

    Potential causes:
    - Inefficient queries or missing indexes
    - High traffic load
    - Long-running transactions

    Investigation steps:
    1. Check Performance Insights for slow queries
    2. Review ECS task count for traffic spikes
    3. Check for long-running transactions in pg_stat_activity

    Remediation:
    - Optimize slow queries
    - Add missing indexes
    - Consider scaling up instance class
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-cpu-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 2: High Database Connections (> 75 connections for db.t3.micro)
resource "aws_cloudwatch_metric_alarm" "connections_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-connections-high"
  alarm_description   = <<-EOT
    RDS database connections are above 75 (86% of max_connections for db.t3.micro).

    Potential causes:
    - Connection leaks in application code
    - Too many ECS tasks running
    - Missing connection pooling configuration

    Investigation steps:
    1. Check ECS task count
    2. Review application logs for connection errors
    3. Query pg_stat_activity to see active connections

    Remediation:
    - Fix connection leaks in application
    - Reduce ECS task count if over-provisioned
    - Tune connection pool settings (HikariCP)
    - Consider scaling up instance for higher max_connections
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 75 # ~86% of 87 max_connections for db.t3.micro
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-connections-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 3: Free Storage Space Low (< 10 GB)
resource "aws_cloudwatch_metric_alarm" "storage_low" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-storage-low"
  alarm_description   = <<-EOT
    RDS free storage space is below 10 GB.

    Potential causes:
    - Database growth (recipes, images metadata, users)
    - WAL files accumulating
    - Temp files from large queries

    Investigation steps:
    1. Check current allocated storage and growth trend
    2. Query table sizes: SELECT * FROM pg_size_pretty(pg_database_size('cookstemma'))
    3. Check for unused indexes or bloated tables

    Remediation:
    - Verify auto-scaling is enabled (max_allocated_storage)
    - Clean up old data if applicable
    - Run VACUUM to reclaim space
    - Increase allocated_storage if needed
  EOT
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-storage-low"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}

# Alarm 4: High Read Latency (> 100ms P99)
resource "aws_cloudwatch_metric_alarm" "read_latency_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-read-latency-high"
  alarm_description   = <<-EOT
    RDS read latency (P99) is above 100ms.

    Potential causes:
    - Missing indexes on frequently queried columns
    - Full table scans
    - High CPU utilization
    - Storage IOPS saturation

    Investigation steps:
    1. Check Performance Insights for slow SELECT queries
    2. Review CPU and IOPS metrics
    3. Analyze query execution plans (EXPLAIN)

    Remediation:
    - Add missing indexes
    - Optimize queries with high latency
    - Consider upgrading to db.t3.small for better IOPS
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 0.1 # 100ms in seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-read-latency-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 5: High Write Latency (> 100ms P99)
resource "aws_cloudwatch_metric_alarm" "write_latency_high" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-write-latency-high"
  alarm_description   = <<-EOT
    RDS write latency (P99) is above 100ms.

    Potential causes:
    - Storage IOPS saturation
    - Long transactions holding locks
    - High WAL write volume

    Investigation steps:
    1. Check IOPS metrics and burst balance
    2. Review Performance Insights for slow INSERT/UPDATE queries
    3. Check for lock contention in pg_stat_activity

    Remediation:
    - Optimize write-heavy queries
    - Reduce transaction size
    - Consider upgrading to db.t3.small for better IOPS
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 0.1 # 100ms in seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-write-latency-high"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "medium"
  }
}

# Alarm 6: Failed SQL Server Connections (> 5 in 5 minutes)
resource "aws_cloudwatch_metric_alarm" "failed_connections" {
  count = local.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-failed-connections"
  alarm_description   = <<-EOT
    RDS has more than 5 failed connection attempts in 5 minutes.

    Potential causes:
    - Incorrect database credentials
    - Max connections reached
    - Security group misconfiguration
    - RDS instance not reachable

    Investigation steps:
    1. Check RDS security group rules
    2. Verify database credentials in Secrets Manager
    3. Check DatabaseConnections metric for max connections
    4. Review application logs for connection errors

    Remediation:
    - Fix security group rules if blocking traffic
    - Rotate credentials if invalid
    - Increase max_connections if at limit
  EOT
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedSQLServerAgentConnectionsCount"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  alarm_actions = [var.sns_alarm_topic_arn]
  ok_actions    = [var.sns_alarm_topic_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-failed-connections"
    Project     = var.project_name
    Environment = var.environment
    Severity    = "high"
  }
}
