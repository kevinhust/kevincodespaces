# Common Tags
locals {
  common_tags = {
    Name        = var.group_name
    Team        = var.group_name
    Project     = "ACS730"
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
    ManagedBy   = var.managed_by
    Terraform   = "true"
  }

  # Resource specific tags
  bastion_tags = merge(local.common_tags, {
    Role        = "Bastion"
    AccessLevel = "Public"
    Type        = "SSH Gateway"
  })

  webserver_tags = merge(local.common_tags, {
    Role        = "WebServer"
    AccessLevel = "Private"
    Type        = "Application"
  })

  alb_tags = merge(local.common_tags, {
    Role        = "LoadBalancer"
    AccessLevel = "Public"
    Type        = "Network"
  })

  network_tags = merge(local.common_tags, {
    Role = "Network"
    Type = "Infrastructure"
  })

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
resource "aws_key_pair" "zombieacs730" {
  key_name   = var.key_name
  public_key = var.ssh_public_key

  tags = merge(local.common_tags, {
    Name        = "${var.group_name}-ssh-key"
    Description = "SSH key for zombie infrastructure"
    Type        = "KeyPair"
  })
}

# Network Module
module "network" {
  source = "./modules/network"

  vpc_cidr = var.vpc_cidr
  public_subnets = local.public_subnets
  private_subnets = local.private_subnets
  group_name  = var.group_name
  common_tags = local.network_tags
}

# ALB Module
module "alb" {
  source = "./modules/ALB"

  vpc_id                = module.network.vpc_id
  public_subnet_ids     = values(module.network.public_subnet_ids)
  web_security_group_id = module.network.web_security_group_id
  group_name           = var.group_name
  common_tags          = local.alb_tags
  s3_bucket           = var.s3_bucket
}

# Webserver Module for ASG
module "webserver" {
  source = "./modules/webserver"

  group_name               = var.group_name
  ami_id                  = var.ami_id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.zombieacs730.key_name
  web_security_group_id   = module.network.web_security_group_id
  private_security_group_id = module.network.private_security_group_id
  target_group_arn        = module.alb.target_group_arn
  s3_bucket               = var.s3_bucket
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids
  common_tags             = local.common_tags
  asg_desired_capacity    = 2
  asg_min_size            = 2
  asg_max_size            = 4
}

# Individual EC2 Instances
resource "aws_instance" "webserver_2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.network.public_subnet_ids["2"]
  vpc_security_group_ids = [module.network.bastion_security_group_id]
  key_name      = aws_key_pair.zombieacs730.key_name
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export WEBSERVER_ID="2"
              export GROUP_NAME="${var.group_name}"
              export S3_BUCKET="${var.s3_bucket}"
              ${file("${path.module}/modules/webserver/setup_single_webserver.sh")}
              EOF
  )

  tags = local.bastion_tags
}

resource "aws_instance" "webserver_4" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.network.public_subnet_ids["4"]
  vpc_security_group_ids = [module.network.web_security_group_id]
  key_name      = aws_key_pair.zombieacs730.key_name
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export WEBSERVER_ID="4"
              export GROUP_NAME="${var.group_name}"
              export S3_BUCKET="${var.s3_bucket}"
              ${file("${path.module}/modules/webserver/setup_single_webserver.sh")}
              EOF
  )

  tags = local.webserver_tags
}

resource "aws_instance" "webserver_5" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.network.private_subnet_ids["1"]
  vpc_security_group_ids = [module.network.private_security_group_id]
  key_name      = aws_key_pair.zombieacs730.key_name
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export WEBSERVER_ID="5"
              export GROUP_NAME="${var.group_name}"
              export S3_BUCKET="${var.s3_bucket}"
              ${file("${path.module}/modules/webserver/setup_single_webserver.sh")}
              EOF
  )

  tags = local.webserver_tags
}

resource "aws_instance" "webserver_6" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.network.private_subnet_ids["2"]
  vpc_security_group_ids = [module.network.private_security_group_id]
  key_name      = aws_key_pair.zombieacs730.key_name
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export WEBSERVER_ID="6"
              export GROUP_NAME="${var.group_name}"
              export S3_BUCKET="${var.s3_bucket}"
              ${file("${path.module}/modules/webserver/setup_single_webserver.sh")}
              EOF
  )

  tags = local.webserver_tags
}

# IAM Role for S3 Access
resource "aws_iam_role" "web_role" {
  name = "${var.group_name}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.group_name}-web-role"
    Type = "IAM"
    Role = "S3Access"
  })
}

resource "aws_iam_policy" "web_policy" {
  name = "${var.group_name}-web-policy"
  description = "Allow web servers to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_role_policy_attachment" {
  role       = aws_iam_role.web_role.name
  policy_arn = aws_iam_policy.web_policy.arn
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "${var.group_name}-web-instance-profile"
  role = aws_iam_role.web_role.name
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = var.s3_bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root" 
        }
        Action = "s3:PutObject"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}/*",
          "arn:aws:s3:::${var.s3_bucket}"
        ]
      }
    ]
  })
}