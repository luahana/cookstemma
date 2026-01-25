# ECS Frontend Module
# Creates ECS cluster, task definition, and service for Next.js web

# ECS Cluster (separate from backend for isolation)
resource "aws_ecs_cluster" "web" {
  name = "${var.project_name}-${var.environment}-web-cluster"

  setting {
    name  = "containerInsights"
    value = var.environment == "prod" ? "enabled" : "disabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-cluster"
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "web" {
  cluster_name = aws_ecs_cluster.web.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.environment == "prod" ? "FARGATE" : "FARGATE_SPOT"
  }
}

# Security Group for ECS Frontend Tasks (only created if not using existing)
resource "aws_security_group" "ecs_web" {
  count       = var.use_existing_security_group ? 0 : 1
  name        = "${var.project_name}-${var.environment}-ecs-web-sg"
  description = "Security group for ECS web tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = var.alb_security_group_id != null ? [var.alb_security_group_id] : []
    cidr_blocks     = var.alb_security_group_id == null ? ["0.0.0.0/0"] : []
    description     = "Next.js application port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-web-sg"
  }
}

locals {
  ecs_web_security_group_id = var.use_existing_security_group ? var.existing_security_group_id : aws_security_group.ecs_web[0].id
}

# CloudWatch Log Group for Frontend
resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${var.project_name}-${var.environment}-web"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-${var.environment}-web-logs"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_web_execution" {
  name = "${var.project_name}-${var.environment}-ecs-web-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-web-execution"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_web_execution" {
  role       = aws_iam_role.ecs_web_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_web_task" {
  name = "${var.project_name}-${var.environment}-ecs-web-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-web-task"
  }
}

# ECS Task Definition for Next.js
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project_name}-${var.environment}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_web_execution.arn
  task_role_arn            = aws_iam_role.ecs_web_task.arn

  # ARM64 = Graviton (20% cost savings), X86_64 = Intel/AMD
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-${var.environment}-web"
      image = var.container_image

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        }
      ], var.internal_api_url != "" ? [
        {
          name  = "INTERNAL_API_URL"
          value = var.internal_api_url
        }
      ] : [])

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 120
      }

      essential = true
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-web-task"
  }
}

# ECS Service for Frontend
resource "aws_ecs_service" "web" {
  name            = "${var.project_name}-${var.environment}-web-service"
  cluster         = aws_ecs_cluster.web.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [local.ecs_web_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = "${var.project_name}-${var.environment}-web"
      container_port   = var.container_port
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-service"
  }
}
