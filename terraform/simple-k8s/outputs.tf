output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i ${var.cluster_name}-key.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "master_private_ips" {
  description = "Private IPs of master nodes"
  value       = aws_instance.masters[*].private_ip
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = aws_instance.workers[*].private_ip
}

output "ssh_to_masters" {
  description = "Commands to SSH to masters from bastion"
  value = [
    for i, master in aws_instance.masters : 
    "ssh -i ~/.ssh/${var.cluster_name}-key.pem ubuntu@${master.private_ip}"
  ]
}

output "ssh_to_workers" {
  description = "Commands to SSH to workers from bastion"
  value = [
    for i, worker in aws_instance.workers : 
    "ssh -i ~/.ssh/${var.cluster_name}-key.pem ubuntu@${worker.private_ip}"
  ]
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    =====================================
    Kubernetes Infrastructure Deployed!
    =====================================
    
    1. SSH to Bastion:
       ssh -i ${var.cluster_name}-key.pem ubuntu@${aws_instance.bastion.public_ip}
    
    2. Copy SSH key to bastion:
       scp -i ${var.cluster_name}-key.pem ${var.cluster_name}-key.pem ubuntu@${aws_instance.bastion.public_ip}:~/.ssh/
    
    3. From bastion, SSH to master-1:
       ssh -i ~/.ssh/${var.cluster_name}-key.pem ubuntu@${aws_instance.masters[0].private_ip}
    
    Master IPs: ${join(", ", aws_instance.masters[*].private_ip)}
    Worker IPs: ${join(", ", aws_instance.workers[*].private_ip)}
    
    4. Install Kubernetes on all nodes (from bastion)
    
    =====================================
  EOT
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_key_path" {
  description = "Path to private SSH key"
  value       = "./${var.cluster_name}-key.pem"
}

