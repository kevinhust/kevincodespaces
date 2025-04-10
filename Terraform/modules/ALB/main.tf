# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.group_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.web_security_group_id]
  subnets           = values(var.public_subnet_ids)

  tags = merge(var.common_tags, {
    Name = "${var.group_name}ALB"
  })
}

# Target Group
resource "aws_lb_target_group" "target_group" {
  name     = "${var.group_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.group_name}TargetGroup"
  })
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
} 