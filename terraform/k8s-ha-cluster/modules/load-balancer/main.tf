# Load Balancer Module for HA Kubernetes Cluster

resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  subnets            = var.subnets

  # Security groups only for Application Load Balancers (ALB)
  # Network Load Balancers (NLB) don't support security groups
  security_groups = var.load_balancer_type == "application" ? var.security_groups : null

  enable_deletion_protection = false

  tags = {
    Name = var.name
  }
}

# Target Group for the Load Balancer
resource "aws_lb_target_group" "main" {
  count = var.create_target_group ? 1 : 0

  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = var.load_balancer_type == "application" ? "HTTP" : "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = var.load_balancer_type == "application" ? 5 : null
    interval            = 30
    port                = var.health_check != null ? var.health_check.port : var.target_port
    protocol            = var.load_balancer_type == "application" ? "HTTP" : "TCP"
    path                = var.load_balancer_type == "application" ? (var.health_check != null ? coalesce(var.health_check.path, "/") : "/") : null
    matcher             = var.load_balancer_type == "application" ? "200-399" : null
  }

  tags = {
    Name = "${var.name}-tg"
  }
}

# HTTP Listener for ALB
resource "aws_lb_listener" "http" {
  count = var.load_balancer_type == "application" && var.create_target_group ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

# TCP Listener for NLB (e.g., Kubernetes API Server)
resource "aws_lb_listener" "tcp" {
  count = var.load_balancer_type == "network" && var.create_target_group ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = var.target_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

# Register targets (EC2 instances)
resource "aws_lb_target_group_attachment" "targets" {
  count = var.create_target_group ? length(var.target_ids) : 0

  target_group_arn = aws_lb_target_group.main[0].arn
  target_id        = var.target_ids[count.index]
  port             = var.target_port
}
