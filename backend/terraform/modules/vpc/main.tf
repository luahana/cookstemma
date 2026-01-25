# VPC Module
# Creates VPC with configurable public/private subnets

locals {
  # Calculate subnet CIDRs based on VPC CIDR
  public_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + var.az_count)]
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Tier = "public"
  }
}

# Private Subnets (only if enabled)
resource "aws_subnet" "private" {
  count = var.create_private_subnets ? var.az_count : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  }
}

# Elastic IP for NAT Gateway (only if NAT is enabled)
resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (only if enabled - for staging/prod)
resource "aws_nat_gateway" "main" {
  count = var.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Private Route Table (with NAT if enabled)
resource "aws_route_table" "private" {
  count  = var.create_private_subnets ? 1 : 0
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.create_private_subnets ? var.az_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# =============================================================================
# VPC Endpoints for Lambda access to AWS services
# =============================================================================

# Get current region
data "aws_region" "current" {}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name        = "${var.project_name}-${var.environment}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  }
}

# S3 Gateway Endpoint (FREE)
resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = compact([
    aws_route_table.public.id,
    var.create_private_subnets ? aws_route_table.private[0].id : ""
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  }
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.public[*].id
  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  tags = {
    Name = "${var.project_name}-${var.environment}-secretsmanager-endpoint"
  }
}

# SQS Interface Endpoint
resource "aws_vpc_endpoint" "sqs" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.public[*].id
  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  tags = {
    Name = "${var.project_name}-${var.environment}-sqs-endpoint"
  }
}
