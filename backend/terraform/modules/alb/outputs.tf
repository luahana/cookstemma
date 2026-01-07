output "alb_id" {
  description = "ID of the ALB"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53)"
  value       = aws_lb.main.zone_id
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "target_group_blue_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "target_group_blue_name" {
  description = "Name of the blue target group"
  value       = aws_lb_target_group.blue.name
}

output "target_group_green_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}

output "target_group_green_name" {
  description = "Name of the green target group"
  value       = aws_lb_target_group.green.name
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

output "test_listener_arn" {
  description = "ARN of the test listener"
  value       = length(aws_lb_listener.test) > 0 ? aws_lb_listener.test[0].arn : null
}
