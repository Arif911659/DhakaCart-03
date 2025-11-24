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

