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

output "bastion_ssm_command" {
  description = "AWS SSM command to connect to bastion (private subnet)"
  value       = "aws ssm start-session --target ${module.bastion.instance_id}"
}

output "bastion_private_ip" {
  description = "Private IP of bastion host"
  value       = module.bastion.private_ip
}

output "bastion_instance_id" {
  description = "Instance ID of bastion host"
  value       = module.bastion.instance_id
}

output "bastion_note" {
  description = "Important note about bastion access"
  value       = "⚠️ AWS POLICY BLOCKS PUBLIC SUBNET EC2! Bastion is in private subnet. Use SSM to access."
}

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
  description = "Command to get kubeconfig from bastion"
  value       = "From bastion: scp -i ~/.ssh/${var.cluster_name}-key.pem ubuntu@${module.master_node_1.private_ip}:/home/ubuntu/.kube/config ~/.kube/config"
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
    
    ⚠️ AWS POLICY RESTRICTION:
    EC2 instances in PUBLIC subnets are BLOCKED!
    Bastion is in PRIVATE subnet. Use AWS SSM to access.
    
    📌 PUBLIC ACCESS URL (DhakaCart Application):
    http://${module.ingress_lb.dns_name}
    
    📌 BASTION ACCESS (via AWS SSM):
    aws ssm start-session --target ${module.bastion.instance_id}
    
    📌 FROM BASTION - SSH to master/worker nodes:
    ssh -i ~/.ssh/${var.cluster_name}-key.pem ubuntu@${module.master_node_1.private_ip}
    
    📌 CLUSTER INFO:
    - Bastion (private): ${module.bastion.private_ip}
    - Master-1: ${module.master_node_1.private_ip}
    - API Server: ${module.api_lb.dns_name}:6443
    
    📌 VERIFY CLUSTER (from master-1):
    kubectl get nodes
    kubectl get pods --all-namespaces
    
    📌 NETWORK ARCHITECTURE:
    - Master/Worker nodes: Private subnets (no public IP)
    - Internet access: Via NAT Gateway ✅
    - Bastion: Private subnet (AWS policy blocks public)
    
    📌 TO GET PUBLIC BASTION:
    Contact AWS admin to remove ec2:RunInstances deny for public subnets
    
    ============================================
  EOT
}

