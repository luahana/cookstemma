# AWS Cloud Map Service Discovery Module
# Creates private DNS namespace for internal service-to-service communication

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}-${var.environment}.local"
  description = "Private DNS namespace for ${var.project_name} ${var.environment}"
  vpc         = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-namespace"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Service discovery service for backend
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-service"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
