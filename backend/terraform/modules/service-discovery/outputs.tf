# Service Discovery Module Outputs

output "namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "namespace_name" {
  description = "Name of the service discovery namespace (e.g., cookstemma-dev.local)"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "namespace_arn" {
  description = "ARN of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.arn
}

output "backend_service_arn" {
  description = "ARN of the backend service discovery service"
  value       = aws_service_discovery_service.backend.arn
}

output "backend_service_id" {
  description = "ID of the backend service discovery service"
  value       = aws_service_discovery_service.backend.id
}

output "backend_dns_name" {
  description = "DNS name for the backend service (e.g., backend.cookstemma-dev.local)"
  value       = "backend.${aws_service_discovery_private_dns_namespace.main.name}"
}

output "backend_api_url" {
  description = "Full internal API URL for the backend"
  value       = "http://backend.${aws_service_discovery_private_dns_namespace.main.name}:4000/api/v1"
}
