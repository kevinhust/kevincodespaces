# Common Tags
locals {
  common_tags = {
    Group   = var.group_name
    Project = "ACS730"
  }

  public_subnets = {
    "1" = { cidr = var.public_subnet_1_cidr, az = var.availability_zone_1 }
    "2" = { cidr = var.public_subnet_2_cidr, az = var.availability_zone_2 }
    "3" = { cidr = var.public_subnet_3_cidr, az = var.availability_zone_3 }
    "4" = { cidr = var.public_subnet_4_cidr, az = var.availability_zone_4 }
  }

  private_subnets = {
    "1" = { cidr = var.private_subnet_1_cidr, az = var.availability_zone_1 }
    "2" = { cidr = var.private_subnet_2_cidr, az = var.availability_zone_2 }
  }
}

# Key Pair
resource "aws_key_pair" "zombie_key" {
  key_name   = "zombie_key"
  public_key = file("${path.module}/zombie_key.pub")

  tags = merge(local.common_tags, {
    Name = "${var.group_name}KeyPair"
  })
}

# Network Module
module "network" {
  source = "./modules/network"

  vpc_cidr        = var.vpc_cidr
  group_name      = var.group_name
  common_tags     = local.common_tags
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
}

# ALB Module
module "alb" {
  source = "./modules/ALB"

  group_name            = var.group_name
  common_tags          = local.common_tags
  vpc_id               = module.network.vpc_id
  web_security_group_id = module.network.web_security_group_id
  public_subnet_ids    = module.network.public_subnet_ids
}

# Webserver Module
module "webserver" {
  source = "./modules/webserver"

  group_name            = var.group_name
  common_tags          = local.common_tags
  s3_bucket            = var.s3_bucket
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  web_security_group_id = module.network.web_security_group_id
  key_name             = aws_key_pair.zombie_key.key_name
  asg_desired_capacity = var.asg_desired_capacity
  asg_max_size         = var.asg_max_size
  asg_min_size         = var.asg_min_size
  target_group_arn     = module.alb.target_group_arn
  public_subnet_ids    = module.network.public_subnet_ids
}