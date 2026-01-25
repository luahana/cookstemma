# NAT Instance Module - Outputs

output "instance_id" {
  description = "ID of the NAT EC2 instance"
  value       = aws_instance.nat.id
}

output "public_ip" {
  description = "Public IP address of the NAT instance"
  value       = aws_eip.nat.public_ip
}

output "security_group_id" {
  description = "ID of the NAT instance security group"
  value       = aws_security_group.nat.id
}
