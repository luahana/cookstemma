# NAT Instance Module
# Cost-effective alternative to NAT Gateway (~$4/mo vs ~$35/mo)
# Provides internet access for private subnet resources (Lambdas → Gemini API)

# =============================================================================
# DATA SOURCES
# =============================================================================

# Latest Amazon Linux 2023 AMI (newer than Amazon Linux 2, better performance)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

resource "aws_security_group" "nat" {
  name        = "${var.project_name}-${var.environment}-nat-instance"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id

  # Allow all traffic from VPC (private subnets need to route through NAT)
  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic (NAT needs to reach internet)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-instance-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# NAT INSTANCE
# =============================================================================

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  source_dest_check           = false # Required for NAT functionality
  vpc_security_group_ids      = [aws_security_group.nat.id]
  associate_public_ip_address = true

  # NAT configuration via user data
  # Using nftables which is the default on AL2023, with iptables compatibility
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    exec > /var/log/nat-setup.log 2>&1
    
    echo "Starting NAT instance configuration..."
    
    # Enable IP forwarding immediately and persistently
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-nat.conf
    
    # Wait for network to be fully ready
    sleep 5
    
    # Get the primary interface name
    PRIMARY_IF=$(ip -o -4 route show to default | awk '{print $5}')
    echo "Primary interface: $PRIMARY_IF"
    
    # Install iptables (AL2023 uses nftables backend)
    dnf install -y iptables-nft
    
    # Flush existing NAT rules and set up new ones
    iptables -t nat -F POSTROUTING
    
    # Add MASQUERADE rule for VPC traffic going out primary interface
    iptables -t nat -A POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE
    
    # Verify the rule was added
    iptables -t nat -L -n -v
    
    # Make iptables rules persistent using nftables
    nft list ruleset > /etc/nftables.conf
    systemctl enable nftables
    
    echo "NAT instance configuration complete!"
    echo "IP forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
  EOF

  # Instance metadata options (IMDSv2 required for security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-instance"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# ELASTIC IP
# =============================================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [aws_instance.nat]
}

# Associate EIP with NAT instance
resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

# =============================================================================
# ROUTE
# =============================================================================

# Route private subnet traffic through NAT instance
resource "aws_route" "private_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}
