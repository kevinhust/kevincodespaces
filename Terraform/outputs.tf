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

output "webserver_instances" {
  description = "Public IPs and other details of the webserver instances"
  value = {
    asg_name = module.webserver.asg_name
    key_name = aws_key_pair.zombie_key.key_name
    security_group_id = module.network.web_security_group_id
  }
}

output "vpc_info" {
  description = "VPC related information"
  value = {
    vpc_id = module.network.vpc_id
    public_subnet_ids = module.network.public_subnet_ids
    private_subnet_ids = module.network.private_subnet_ids
  }
}
