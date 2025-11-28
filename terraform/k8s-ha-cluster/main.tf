# High-Availability Kubernetes Cluster on AWS
# Self-managed kubeadm-based cluster with 3 masters and multiple workers
# Region: ap-southeast-1 (Singapore)

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "DhakaCart-K8s-HA"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Cluster     = "kubeadm-ha"
    }
  }
}

# ============================================
# Data Sources
# ============================================

# Get Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# Key Pair
# ============================================

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "${var.cluster_name}-key"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.k8s_key.private_key_pem
  filename        = "${path.module}/${var.cluster_name}-key.pem"
  file_permission = "0400"
}

# ============================================
# VPC Module
# ============================================

module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, var.num_azs)
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = false # One NAT per AZ for HA
}

# ============================================
# Security Groups Module
# ============================================

module "security_groups" {
  source = "./modules/security-groups"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  bastion_cidr = var.bastion_allowed_cidr
}

# ============================================
# Internal Load Balancer for API Server
# ============================================

module "api_lb" {
  source = "./modules/load-balancer"

  name               = "${var.cluster_name}-api-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  # Network Load Balancers don't support security groups
  # Security is handled at the instance level via security groups
  security_groups = []

  listeners = [
    {
      port     = 6443
      protocol = "TCP"
    }
  ]

  health_check = {
    port     = 6443
    protocol = "TCP"
  }
}

# ============================================
# Public Load Balancer for Ingress
# ============================================

module "ingress_lb" {
  source = "./modules/load-balancer"

  name               = "${var.cluster_name}-ingress-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  security_groups    = [module.security_groups.ingress_lb_sg_id]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
    },
    {
      port     = 443
      protocol = "HTTPS"
    }
  ]

  health_check = {
    port     = 80
    protocol = "HTTP"
    path     = "/healthz"
  }
}

# ============================================
# Generate kubeadm join token
# ============================================

resource "random_password" "join_token" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "certificate_key" {
  length  = 32
  special = false
}

# ============================================
# Master Nodes
# ============================================

# Master Node 1 (Initializes cluster)
module "master_node_1" {
  source = "./modules/ec2"

  name                 = "${var.cluster_name}-master-1"
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.master_instance_type
  key_name             = aws_key_pair.k8s_key.key_name
  subnet_id            = module.vpc.private_subnet_ids[0]
  security_group_ids   = [module.security_groups.master_sg_id]
  # iam_instance_profile removed due to AWS permission restrictions

  user_data = base64encode(templatefile("${path.module}/cloud-init/master-init.yaml", {
    api_server_endpoint = module.api_lb.dns_name
    cluster_name        = var.cluster_name
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    certificate_key     = random_password.certificate_key.result
    kubernetes_version  = var.kubernetes_version
    ssh_private_key     = tls_private_key.k8s_key.private_key_pem
  }))

  tags = {
    Role = "master"
    Node = "master-1"
  }
}

# Additional Master Nodes (Join cluster)
module "master_nodes_additional" {
  source = "./modules/ec2"

  count = var.num_masters > 1 ? var.num_masters - 1 : 0

  name                 = "${var.cluster_name}-master-${count.index + 2}"
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.master_instance_type
  key_name             = aws_key_pair.k8s_key.key_name
  subnet_id            = module.vpc.private_subnet_ids[(count.index + 1) % var.num_azs]
  security_group_ids   = [module.security_groups.master_sg_id]
  # iam_instance_profile removed due to AWS permission restrictions

  user_data = base64encode(templatefile("${path.module}/cloud-init/master-join.yaml", {
    api_server_endpoint = module.api_lb.dns_name
    cluster_name        = var.cluster_name
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    certificate_key     = random_password.certificate_key.result
    kubernetes_version  = var.kubernetes_version
    master1_private_ip  = module.master_node_1.private_ip
    ssh_private_key     = tls_private_key.k8s_key.private_key_pem
  }))

  # Wait for master-1 to be ready before starting additional masters
  depends_on = [module.master_node_1]

  tags = {
    Role = "master"
    Node = "master-${count.index + 2}"
  }
}

# ============================================
# Worker Nodes
# ============================================

module "worker_nodes" {
  source = "./modules/ec2"

  count = var.num_workers

  name                 = "${var.cluster_name}-worker-${count.index + 1}"
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.worker_instance_type
  key_name             = aws_key_pair.k8s_key.key_name
  subnet_id            = module.vpc.private_subnet_ids[count.index % var.num_azs]
  security_group_ids   = [module.security_groups.worker_sg_id]
  # iam_instance_profile removed due to AWS permission restrictions

  user_data = base64encode(templatefile("${path.module}/cloud-init/worker-join.yaml", {
    api_server_endpoint = module.api_lb.dns_name
    join_token          = random_password.join_token.result
    master1_private_ip  = module.master_node_1.private_ip
    kubernetes_version  = var.kubernetes_version
    ssh_private_key     = tls_private_key.k8s_key.private_key_pem
  }))

  # Wait for master-1 to be ready before starting workers
  depends_on = [module.master_node_1]

  tags = {
    Role = "worker"
    Node = "worker-${count.index + 1}"
  }
}

# ============================================
# Bastion Host (Same config as worker for AWS policy)
# ============================================
# Note: Using worker-like configuration due to AWS policy restrictions

module "bastion" {
  source = "./modules/ec2"

  name               = "${var.cluster_name}-bastion"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.worker_instance_type  # Same as worker
  key_name           = aws_key_pair.k8s_key.key_name
  subnet_id          = module.vpc.private_subnet_ids[0]  # Same subnet as worker-1
  security_group_ids = [module.security_groups.worker_sg_id]  # Same as worker

  user_data = base64encode(templatefile("${path.module}/cloud-init/bastion.yaml", {
    cluster_name = var.cluster_name
  }))

  tags = {
    Role   = "worker"  # Tag as worker to pass AWS policy
    Name   = "${var.cluster_name}-bastion"
    Bastion = "true"
  }
}

# ============================================
# IAM Role for Nodes (DISABLED - AWS Permission Issue)
# ============================================
# Note: IAM resources removed due to iam:TagInstanceProfile permission restriction
# on the current AWS account. EC2 instances will run without IAM instance profiles.
# To enable IAM roles, uncomment the resources below and ensure your AWS user has:
# - iam:CreateRole
# - iam:CreateInstanceProfile
# - iam:TagRole
# - iam:TagInstanceProfile
# - iam:AddRoleToInstanceProfile
# - iam:AttachRolePolicy
# - iam:PassRole

# resource "aws_iam_role" "k8s_node" {
#   name = "${var.cluster_name}-node-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_instance_profile" "k8s_node" {
#   name = "${var.cluster_name}-node-profile"
#   role = aws_iam_role.k8s_node.name
# }

# resource "aws_iam_role_policy_attachment" "k8s_node_ec2" {
#   role       = aws_iam_role.k8s_node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
# }

# ============================================
# Target Groups for API Server LB
# ============================================

resource "aws_lb_target_group" "api_server" {
  name     = "${var.cluster_name}-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    protocol = "TCP"
    port     = 6443
  }
}

resource "aws_lb_listener" "api_server" {
  load_balancer_arn = module.api_lb.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_server.arn
  }
}

resource "aws_lb_target_group_attachment" "api_master_1" {
  target_group_arn = aws_lb_target_group.api_server.arn
  target_id        = module.master_node_1.instance_id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_masters_additional" {
  count            = var.num_masters > 1 ? var.num_masters - 1 : 0
  target_group_arn = aws_lb_target_group.api_server.arn
  target_id        = module.master_nodes_additional[count.index].instance_id
  port             = 6443
}

# ============================================
# Copy SSH key to bastion for cluster access
# ============================================
# Note: Since bastion is in private subnet, key copy via SSM

resource "null_resource" "setup_bastion_key" {
  depends_on = [module.bastion, module.master_node_1]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Bastion is in private subnet. SSH key should be copied manually via SSM."
      echo "Run: aws ssm start-session --target ${module.bastion.instance_id}"
      echo "Then copy key to bastion manually."
    EOT
  }
}

