# Security Groups Module for HA Kubernetes Cluster

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-bastion-sg"
  }
}

# Security Group for Master Nodes
resource "aws_security_group" "master" {
  name        = "${var.cluster_name}-master-sg"
  description = "Security group for Kubernetes master nodes"
  vpc_id      = var.vpc_id

  # etcd client API
  ingress {
    description = "etcd client API from masters"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    self        = true
  }

  # etcd peer communication
  ingress {
    description = "etcd peer communication from masters"
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  # kube-scheduler
  ingress {
    description = "kube-scheduler from masters"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    self        = true
  }

  # kube-controller-manager
  ingress {
    description = "kube-controller-manager from masters"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    self        = true
  }

  # All traffic from same security group (for master-to-master communication)
  ingress {
    description = "All traffic from masters"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Kubernetes API Server from bastion (non-circular)
  ingress {
    description     = "Kubernetes API Server from bastion"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Kubelet API from bastion (non-circular)
  ingress {
    description     = "Kubelet API from bastion"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-master-sg"
  }
}

# Security Group for Worker Nodes
resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  # Kubelet API from bastion (non-circular)
  ingress {
    description     = "Kubelet API from bastion"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # NodePort Services
  ingress {
    description = "NodePort services from anywhere"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All traffic from same security group (for pod-to-pod communication)
  ingress {
    description = "All traffic from workers"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-worker-sg"
  }
}

# Security Group for Internal API Load Balancer
resource "aws_security_group" "api_lb" {
  name        = "${var.cluster_name}-api-lb-sg"
  description = "Security group for internal API Load Balancer"
  vpc_id      = var.vpc_id

  # Kubernetes API Server from bastion and master (non-circular)
  ingress {
    description     = "Kubernetes API Server from bastion and masters"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id, aws_security_group.master.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-api-lb-sg"
  }
}

# Security Group for Public Ingress Load Balancer
resource "aws_security_group" "ingress_lb" {
  name        = "${var.cluster_name}-ingress-lb-sg"
  description = "Security group for public Ingress Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-ingress-lb-sg"
  }
}

# ============================================
# Security Group Rules (to break circular dependencies)
# ============================================

# Master: Kubernetes API Server from workers
resource "aws_security_group_rule" "master_api_from_workers" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.master.id
  description              = "Kubernetes API Server from workers"
}

# Master: Kubelet API from workers
resource "aws_security_group_rule" "master_kubelet_from_workers" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.master.id
  description              = "Kubelet API from workers"
}

# Worker: Kubelet API from masters
resource "aws_security_group_rule" "worker_kubelet_from_masters" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master.id
  security_group_id        = aws_security_group.worker.id
  description              = "Kubelet API from masters"
}

# Worker: All traffic from masters (for networking)
resource "aws_security_group_rule" "worker_all_from_masters" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.master.id
  security_group_id        = aws_security_group.worker.id
  description              = "All traffic from masters"
}

# API LB: Kubernetes API Server from workers (already has master and bastion inline)
resource "aws_security_group_rule" "api_lb_from_workers" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.api_lb.id
  description              = "Kubernetes API Server from workers"
}

