output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private_sg.id
} 