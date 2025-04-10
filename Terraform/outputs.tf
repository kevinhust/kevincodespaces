output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.network.web_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.network.bastion_security_group_id
}
