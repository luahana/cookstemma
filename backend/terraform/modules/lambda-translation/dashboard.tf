# =============================================================================
# CLOUDWATCH DASHBOARD FOR TRANSLATION MONITORING
# Provides visibility into hybrid push/pull architecture
# =============================================================================

resource "aws_cloudwatch_dashboard" "translation_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-translation-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Lambda Performance
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Total Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Throttles", { stat = "Sum", label = "Throttles" }],
            [".", "ConcurrentExecutions", { stat = "Maximum", label = "Concurrent Executions" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-2"
          title   = "Lambda Invocations & Errors"
          period  = 300
          dimensions = {
            FunctionName = aws_lambda_function.translator.function_name
          }
        }
      },

      # Lambda Duration
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "Average", label = "Avg Duration" }],
            ["...", { stat = "Maximum", label = "Max Duration" }],
            ["...", { stat = "p99", label = "p99 Duration" }]
          ]
          view   = "timeSeries"
          region = "us-east-2"
          title  = "Lambda Duration (ms)"
          period = 300
          yAxis = {
            left = {
              min = 0
              max = 600000  # 10 minutes in ms
            }
          }
          dimensions = {
            FunctionName = aws_lambda_function.translator.function_name
          }
          annotations = {
            horizontal = [
              {
                label = "Timeout Warning (9 min)"
                value = 540000
                fill  = "above"
                color = "#ff7f0e"
              },
              {
                label = "Timeout (10 min)"
                value = 600000
                fill  = "above"
                color = "#d62728"
              }
            ]
          }
        }
      },

      # SQS Queue Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Average", label = "Messages in Queue" }],
            [".", "ApproximateNumberOfMessagesNotVisible", { stat = "Average", label = "Messages In Flight" }],
            [".", "NumberOfMessagesSent", { stat = "Sum", label = "Messages Sent" }],
            [".", "NumberOfMessagesReceived", { stat = "Sum", label = "Messages Received" }],
            [".", "NumberOfMessagesDeleted", { stat = "Sum", label = "Messages Processed" }]
          ]
          view   = "timeSeries"
          region = "us-east-2"
          title  = "SQS Queue Activity (Push Path)"
          period = 300
          dimensions = {
            QueueName = aws_sqs_queue.translation_queue.name
          }
        }
      },

      # Dead Letter Queue
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Average", label = "Failed Messages" }]
          ]
          view   = "timeSeries"
          region = "us-east-2"
          title  = "Dead Letter Queue (Failed After 3 Retries)"
          period = 300
          dimensions = {
            QueueName = aws_sqs_queue.translation_dlq.name
          }
          yAxis = {
            left = {
              min = 0
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Alert Threshold"
                value = 1
                fill  = "above"
                color = "#d62728"
              }
            ]
          }
        }
      },

      # SQS Message Age
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", { stat = "Maximum", label = "Oldest Message Age (seconds)" }]
          ]
          view   = "timeSeries"
          region = "us-east-2"
          title  = "SQS Queue Lag (Real-Time Processing Health)"
          period = 300
          dimensions = {
            QueueName = aws_sqs_queue.translation_queue.name
          }
          annotations = {
            horizontal = [
              {
                label = "Healthy (< 1 min)"
                value = 60
                fill  = "below"
                color = "#2ca02c"
              },
              {
                label = "Warning (> 5 min)"
                value = 300
                fill  = "above"
                color = "#ff7f0e"
              }
            ]
          }
        }
      },

      # Lambda Concurrent Executions
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "ConcurrentExecutions", { stat = "Maximum", label = "Max Concurrent" }],
            ["...", { stat = "Average", label = "Avg Concurrent" }]
          ]
          view   = "timeSeries"
          region = "us-east-2"
          title  = "Lambda Concurrency (Scalability)"
          period = 300
          dimensions = {
            FunctionName = aws_lambda_function.translator.function_name
          }
          # Note: yAxis removed - reserved_concurrent_executions is -1 (unreserved)
          # CloudWatch will auto-scale based on actual concurrency values
        }
      }
    ]
  })

  depends_on = [
    aws_lambda_function.translator,
    aws_sqs_queue.translation_queue,
    aws_sqs_queue.translation_dlq
  ]
}

# Output dashboard URL for easy access
output "dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-2#dashboards:name=${aws_cloudwatch_dashboard.translation_monitoring.dashboard_name}"
  description = "URL to CloudWatch dashboard for translation monitoring"
}
