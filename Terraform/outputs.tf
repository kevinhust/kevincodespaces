output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.network.web_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.network.bastion_security_group_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.webserver_2.public_ip
}

output "webserver_instances" {
  description = "Details of the webserver instances"
  value = {
    webserver_2 = {
      id         = aws_instance.webserver_2.id
      public_ip  = aws_instance.webserver_2.public_ip
      private_ip = aws_instance.webserver_2.private_ip
      subnet_id  = aws_instance.webserver_2.subnet_id
      key_name   = aws_key_pair.zombieacs730.key_name
    }
    webserver_4 = {
      id         = aws_instance.webserver_4.id
      public_ip  = aws_instance.webserver_4.public_ip
      private_ip = aws_instance.webserver_4.private_ip
      subnet_id  = aws_instance.webserver_4.subnet_id
      key_name   = aws_key_pair.zombieacs730.key_name
    }
    webserver_5 = {
      id         = aws_instance.webserver_5.id
      private_ip = aws_instance.webserver_5.private_ip
      subnet_id  = aws_instance.webserver_5.subnet_id
      key_name   = aws_key_pair.zombieacs730.key_name
    }
    webserver_6 = {
      id         = aws_instance.webserver_6.id
      private_ip = aws_instance.webserver_6.private_ip
      subnet_id  = aws_instance.webserver_6.subnet_id
      key_name   = aws_key_pair.zombieacs730.key_name
    }
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

output "webserver_4_public_ip" {
  description = "Public IP of Webserver 4"
  value       = aws_instance.webserver_4.public_ip
}

output "webserver_5_private_ip" {
  description = "Private IP of Webserver 5"
  value       = aws_instance.webserver_5.private_ip
}

output "webserver_6_private_ip" {
  description = "Private IP of Webserver 6"
  value       = aws_instance.webserver_6.private_ip
}
