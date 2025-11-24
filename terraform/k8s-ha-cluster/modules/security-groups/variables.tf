variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "bastion_cidr" {
  description = "CIDR block allowed to access bastion"
  type        = string
  default     = "0.0.0.0/0"
}

