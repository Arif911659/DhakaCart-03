# Load Balancer Module for HA Kubernetes Cluster

resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups     = var.security_groups
  subnets            = var.subnets

  enable_deletion_protection = false

  tags = {
    Name = var.name
  }
}

