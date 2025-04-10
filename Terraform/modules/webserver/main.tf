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

  tags = merge(var.common_tags, {
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
  policy_arn = aws_iam_policy.web_policy.arn
  role       = aws_iam_role.web_role.name
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "${var.group_name}WebInstanceProfile"
  role = aws_iam_role.web_role.name
}

# Launch Configuration
resource "aws_launch_configuration" "launch_config" {
  name_prefix          = "${var.group_name}-web-"
  image_id             = var.ami_id
  instance_type        = var.instance_type
  security_groups      = [var.web_security_group_id]
  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.name
  key_name            = var.key_name
  user_data           = templatefile("${path.module}/setup_webserver.sh", {
    WEBSERVER_ID = "asg"
    GROUP_NAME   = var.group_name
    S3_BUCKET    = var.s3_bucket
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "${var.group_name}-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  target_group_arns   = [var.target_group_arn]
  vpc_zone_identifier = values(var.public_subnet_ids)

  launch_configuration = aws_launch_configuration.launch_config.name

  tag {
    key                 = "Name"
    value              = "${var.group_name}WebServer"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }
} 