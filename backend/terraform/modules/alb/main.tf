# ALB Module
# Creates Application Load Balancer for staging/prod environments

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod"

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Target Group (Blue - Primary)
resource "aws_lb_target_group" "blue" {
  name        = "${var.project_name}-${var.environment}-tg-blue"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg-blue"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group (Green - For Blue/Green deployment)
resource "aws_lb_target_group" "green" {
  name        = "${var.project_name}-${var.environment}-tg-green"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg-green"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group for Frontend (Next.js)
resource "aws_lb_target_group" "web" {
  count = var.enable_web ? 1 : 0

  name        = "${var.project_name}-${var.environment}-tg-web"
  port        = var.web_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.web_health_check_path
    matcher             = "200,307"  # 307 for Next.js i18n redirects
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg-web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener - forwards to target group if no cert, redirects to HTTPS if cert exists
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # When no certificate and web enabled, default to web
  dynamic "default_action" {
    for_each = var.certificate_arn == null && var.enable_web ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.web[0].arn
    }
  }

  # When no certificate and no web, forward to backend
  dynamic "default_action" {
    for_each = var.certificate_arn == null && !var.enable_web ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.blue.arn
    }
  }

  # When certificate exists, redirect HTTP to HTTPS
  dynamic "default_action" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# Listener Rule for API paths (when web is enabled, route /api/* to backend)
resource "aws_lb_listener_rule" "api_rule" {
  count = var.enable_web && var.certificate_arn == null ? 1 : 0

  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Listener Rule for Actuator paths (when web is enabled, route /actuator/* to backend)
resource "aws_lb_listener_rule" "actuator_rule" {
  count = var.enable_web && var.certificate_arn == null ? 1 : 0

  listener_arn = aws_lb_listener.http.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/actuator/*"]
    }
  }
}

# HTTPS Listener (Production Traffic)
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  # When web is enabled, default to web; otherwise default to backend
  default_action {
    type             = "forward"
    target_group_arn = var.enable_web ? aws_lb_target_group.web[0].arn : aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# HTTPS Listener Rule for API paths (route /api/* to backend)
resource "aws_lb_listener_rule" "https_api_rule" {
  count = var.certificate_arn != null && var.enable_web ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# HTTPS Listener Rule for Actuator paths (route /actuator/* to backend)
resource "aws_lb_listener_rule" "https_actuator_rule" {
  count = var.certificate_arn != null && var.enable_web ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/actuator/*"]
    }
  }
}

# Test Listener (For Blue/Green deployment testing - port 8443)
resource "aws_lb_listener" "test" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}
