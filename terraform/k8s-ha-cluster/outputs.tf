# Outputs for HA Kubernetes Cluster

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "api_server_endpoint" {
  description = "Internal Load Balancer DNS for Kubernetes API Server"
  value       = module.api_lb.dns_name
  sensitive   = false
}

output "api_server_port" {
  description = "Kubernetes API Server port"
  value       = 6443
}

output "ingress_lb_endpoint" {
  description = "Public Load Balancer DNS for Ingress"
  value       = module.ingress_lb.dns_name
}

# Bastion outputs disabled - bastion not created due to AWS permission restrictions
# output "bastion_ssh_command" {
#   description = "SSH command to connect to bastion host"
#   value       = "ssh -i ${var.cluster_name}-key.pem ubuntu@${module.bastion.public_ip}"
# }

# output "bastion_public_ip" {
#   description = "Public IP of bastion host"
#   value       = module.bastion.public_ip
# }

output "master_nodes" {
  description = "Master node information"
  value = merge(
    {
      "master-1" = {
        private_ip  = module.master_node_1.private_ip
        instance_id = module.master_node_1.instance_id
      }
    },
    {
      for idx, node in module.master_nodes_additional : "master-${idx + 2}" => {
        private_ip  = node.private_ip
        instance_id = node.instance_id
      }
    }
  )
}

output "worker_nodes" {
  description = "Worker node information"
  value = {
    for idx, node in module.worker_nodes : "worker-${idx + 1}" => {
      private_ip  = node.private_ip
      instance_id = node.instance_id
    }
  }
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from master1 (use AWS SSM or VPN to access)"
  value       = "Use AWS SSM Session Manager to connect to master-1 (${module.master_node_1.private_ip}) and copy kubeconfig"
}

output "join_token" {
  description = "kubeadm join token (for future nodes)"
  value       = random_password.join_token.result
  sensitive   = true
}

output "certificate_key" {
  description = "Certificate key for joining control plane nodes"
  value       = random_password.certificate_key.result
  sensitive   = true
}

output "kubeadm_join_command_worker" {
  description = "kubeadm join command for worker nodes"
  value       = "kubeadm join ${module.api_lb.dns_name}:6443 --token ${random_password.join_token.result} --discovery-token-unsafe-skip-ca-verification"
  sensitive   = true
}

output "kubeadm_join_command_master" {
  description = "kubeadm join command for additional master nodes"
  value       = "kubeadm join ${module.api_lb.dns_name}:6443 --token ${random_password.join_token.result} --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key ${random_password.certificate_key.result}"
  sensitive   = true
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = "${path.module}/${var.cluster_name}-key.pem"
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    ============================================
    Kubernetes HA Cluster Deployment Complete!
    ============================================
    
    NOTE: Bastion host not created due to AWS permission restrictions.
    Use AWS SSM Session Manager to access nodes.
    
    1. Access master-1 via AWS SSM:
       aws ssm start-session --target ${module.master_node_1.instance_id}
    
    2. Or use EC2 Instance Connect from AWS Console
    
    3. Master-1 Private IP: ${module.master_node_1.private_ip}
    
    4. Verify cluster (from master-1):
       kubectl get nodes
       kubectl get pods --all-namespaces
    
    5. API Server Endpoint: ${module.api_lb.dns_name}:6443
    
    6. Ingress Endpoint: http://${module.ingress_lb.dns_name}
    
    ============================================
  EOT
}

