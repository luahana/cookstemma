output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_secretsmanager_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.secretsmanager[0].id : null
}

output "vpc_endpoint_sqs_id" {
  description = "ID of the SQS VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.sqs[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = var.create_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = var.create_private_subnets ? aws_route_table.private[0].id : null
}
