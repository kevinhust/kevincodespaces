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
  public_key = var.ssh_public_key

  tags = merge(
    local.common_tags,
    {
      Description = "SSH key for zombie infrastructure"
    }
  )
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

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.group_name}VPC"
  })
}

# Subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.group_name}PublicSubnet${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.group_name}PrivateSubnet${each.key}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.group_name}IGW"
  })
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.group_name}NATEIP"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public["1"].id
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(local.common_tags, {
    Name = "${var.group_name}NAT"
  })
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}PublicRouteTable"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}PrivateRouteTable"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "web_sg" {
  name        = "${var.group_name}WebSG"
  description = "Allow HTTP and SSH traffic for public webservers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}WebSG"
  })
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.group_name}BastionSG"
  description = "Allow SSH access for Bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}BastionSG"
  })
}

resource "aws_security_group" "private_sg" {
  name        = "${var.group_name}PrivateSG"
  description = "Allow SSH access from Bastion host for private subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}PrivateSG"
  })
}

# IAM Role for S3 Access
resource "aws_iam_role" "web_role" {
  name = "${var.group_name}WebRole"

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
    Name = "${var.group_name}WebRole"
  })
}

resource "aws_iam_policy" "web_policy" {
  name        = "${var.group_name}WebPolicy"
  description = "Policy for web servers to access S3"

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
  name = "${var.group_name}WebInstanceProfile"
  role = aws_iam_role.web_role.name
}

# EC2 Instances
locals {
  webservers = {
    "1" = { subnet = aws_subnet.public["1"].id, sg = aws_security_group.web_sg.id, public = true, user_data = true }
    "2" = { subnet = aws_subnet.public["2"].id, sg = aws_security_group.bastion_sg.id, public = true, user_data = false }
    "3" = { subnet = aws_subnet.public["3"].id, sg = aws_security_group.web_sg.id, public = true, user_data = false }
    "4" = { subnet = aws_subnet.public["4"].id, sg = aws_security_group.web_sg.id, public = true, user_data = false }
    "5" = { subnet = aws_subnet.private["1"].id, sg = aws_security_group.private_sg.id, public = false, user_data = true }
    "6" = { subnet = aws_subnet.private["2"].id, sg = aws_security_group.private_sg.id, public = false, user_data = true }
  }
}

resource "aws_instance" "webserver" {
  for_each = local.webservers

  ami                     = var.ami_id
  instance_type           = var.instance_type
  subnet_id               = each.value.subnet
  vpc_security_group_ids  = [each.value.sg]
  key_name                = aws_key_pair.zombie_key.key_name
  associate_public_ip_address = each.value.public
  iam_instance_profile    = each.value.user_data ? aws_iam_instance_profile.web_instance_profile.name : null

  user_data = each.value.user_data ? templatefile("${path.root}/modules/webserver/setup_webserver.sh", { 
    WEBSERVER_ID = each.key,
    GROUP_NAME = var.group_name,
    S3_BUCKET = var.s3_bucket
  }) : <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y epel-release
              sudo yum install -y ansible
              EOF

  tags = merge(local.common_tags, {
    Name = "${var.group_name}Webserver${each.key}"
    Role = each.key == "2" ? "Bastion" : null
  })
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.group_name}ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  tags = merge(local.common_tags, {
    Name = "${var.group_name}ALB"
  })
}

resource "aws_lb_target_group" "target_group" {
  name     = "${var.group_name}TargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}TargetGroup"
  })
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.group_name}ALBListener"
  })
}

resource "aws_lb_target_group_attachment" "webserver" {
  for_each = { for k, v in local.webservers : k => v if k != "2" && k != "4" }

  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.webserver[each.key].id
  port             = 80
}

# Auto Scaling Group
resource "aws_launch_template" "launch_template" {
  name_prefix   = "Zombies-web-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.web_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.web_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.root}/modules/webserver/setup_webserver.sh", { 
    WEBSERVER_ID = "asg",
    GROUP_NAME = var.group_name,
    S3_BUCKET = var.s3_bucket
  }))

  key_name = aws_key_pair.zombie_key.key_name

  tags = merge(local.common_tags, {
    Name = "${var.group_name}LaunchTemplate"
  })
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.group_name}ASG"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  target_group_arns   = [aws_lb_target_group.target_group.arn]
  vpc_zone_identifier = [
    aws_subnet.public["1"].id,
    aws_subnet.public["3"].id
  ]
  health_check_type          = "ELB"
  health_check_grace_period  = 300

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value              = "${var.group_name}ASG"
    propagate_at_launch = true
  }
}