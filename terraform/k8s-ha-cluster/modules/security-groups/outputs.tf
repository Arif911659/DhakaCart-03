output "bastion_sg_id" {
  description = "Security group ID for bastion"
  value       = aws_security_group.bastion.id
}

output "master_sg_id" {
  description = "Security group ID for master nodes"
  value       = aws_security_group.master.id
}

output "worker_sg_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.worker.id
}

output "api_lb_sg_id" {
  description = "Security group ID for API Load Balancer"
  value       = aws_security_group.api_lb.id
}

output "ingress_lb_sg_id" {
  description = "Security group ID for Ingress Load Balancer"
  value       = aws_security_group.ingress_lb.id
}

