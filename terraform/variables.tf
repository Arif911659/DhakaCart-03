# Terraform Variables
# These are settings you can customize

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"  # Singapore
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "dhakacart"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of AWS key pair for SSH access (DEPRECATED: Key pair is now auto-generated)"
  type        = string
  default     = ""
  # Note: Key pair is now automatically created. This variable is kept for backward compatibility but not used.
}

variable "min_instances" {
  description = "Minimum number of instances in auto-scaling group"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances in auto-scaling group"
  type        = number
  default     = 10
}

variable "desired_instances" {
  description = "Desired number of instances in auto-scaling group"
  type        = number
  default     = 3
}

# Docker Images
variable "backend_docker_image" {
  description = "Docker image for backend"
  type        = string
  default     = "arifhossaincse22/dhakacart-backend:latest"
}

variable "frontend_docker_image" {
  description = "Docker image for frontend"
  type        = string
  default     = "arifhossaincse22/dhakacart-frontend:latest"
}

# Database Configuration (Docker Container)
# NOTE: Using Docker containers instead of RDS for simplified version
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "dhakacart_db"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "dhakacart"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  # Set this in terraform.tfvars or as environment variable
  # Never commit passwords to Git!
}

# Redis Configuration (Docker Container)
# NOTE: Using Docker containers instead of ElastiCache for simplified version
# No additional variables needed - Redis runs as Docker container

