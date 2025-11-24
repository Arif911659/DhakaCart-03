# High-Availability Kubernetes Cluster on AWS

This Terraform configuration creates a fully automated, self-managed Kubernetes cluster using kubeadm on AWS in the `ap-southeast-1` (Singapore) region.

## 🎯 Features

- **3 Master Nodes** for High Availability
- **2+ Worker Nodes** for workload distribution
- **Internal Load Balancer** for Kubernetes API Server (port 6443)
- **Public Load Balancer** for Ingress traffic
- **Bastion Host** for secure access
- **Multi-AZ Deployment** across 2-3 Availability Zones
- **Automated Setup** using cloud-init scripts
- **Calico CNI** automatically installed
- **Production-Ready** security groups and networking

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **kubectl** installed (for cluster access)

### Required AWS Permissions

- EC2 (instances, security groups, VPC, subnets, load balancers)
- IAM (roles, instance profiles)
- EIP (Elastic IPs for NAT Gateways)

## 🚀 Quick Start

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: ap-southeast-1
# Default output format: json
```

### 2. Navigate to Directory

```bash
cd terraform/k8s-ha-cluster
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

This will show you what resources will be created:
- 1 VPC with public/private subnets
- 3 NAT Gateways (one per AZ)
- 3 Master nodes
- 2 Worker nodes (configurable)
- 1 Bastion host
- 2 Load Balancers (internal API, public Ingress)
- Security Groups
- IAM roles

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This will take approximately **15-20 minutes** to complete.

### 6. Get Cluster Information

After deployment completes, get the outputs:

```bash
terraform output
```

Key outputs:
- `api_server_endpoint` - Kubernetes API Server endpoint
- `bastion_ssh_command` - SSH command to connect to bastion
- `kubeconfig_command` - Command to get kubeconfig
- `kubeadm_join_command_worker` - Command to join new worker nodes
- `kubeadm_join_command_master` - Command to join new master nodes

## 📖 Detailed Usage

### Access the Cluster

1. **Connect to Bastion:**
   ```bash
   ssh -i dhakacart-k8s-ha-key.pem ubuntu@<bastion-ip>
   ```

2. **From Bastion, connect to Master1:**
   ```bash
   ssh -i dhakacart-k8s-ha-key.pem ubuntu@<master1-private-ip>
   ```

3. **Get kubeconfig:**
   ```bash
   # On master1
   cat ~/.kube/config
   
   # Or copy to local machine
   scp -i dhakacart-k8s-ha-key.pem ubuntu@<bastion-ip>:~/.kube/config ~/.kube/config
   ```

4. **Verify Cluster:**
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

### Configuration

Edit `terraform.tfvars` (create from example):

```hcl
cluster_name         = "dhakacart-k8s-ha"
aws_region          = "ap-southeast-1"
num_masters         = 3
num_workers         = 2
master_instance_type = "t3.medium"
worker_instance_type = "t3.medium"
kubernetes_version   = "1.28.0"
```

### Adding More Nodes

#### Add Worker Node:

1. Get join command:
   ```bash
   terraform output kubeadm_join_command_worker
   ```

2. SSH to new worker instance and run the command

#### Add Master Node:

1. Get join command:
   ```bash
   terraform output kubeadm_join_command_master
   ```

2. SSH to new master instance and run the command

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet Gateway                      │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
   │ Public  │     │ Public  │     │ Public  │
   │ Subnet  │     │ Subnet  │     │ Subnet  │
   │   AZ1   │     │   AZ2   │     │   AZ3   │
   └────┬────┘     └────┬────┘     └────┬────┘
        │               │               │
   ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
   │ Bastion │     │  NAT    │     │  NAT    │
   │  Host   │     │ Gateway │     │ Gateway │
   └─────────┘     └────┬────┘     └────┬────┘
                        │               │
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
   │Private  │     │Private  │     │Private  │
   │ Subnet  │     │ Subnet  │     │ Subnet  │
   │   AZ1   │     │   AZ2   │     │   AZ3   │
   └────┬────┘     └────┬────┘     └────┬────┘
        │               │               │
   ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
   │Master-1 │     │Master-2 │     │Master-3 │
   │Worker-1 │     │Worker-2 │     │         │
   └─────────┘     └─────────┘     └─────────┘
        │               │               │
        └───────────────┼───────────────┘
                        │
            ┌───────────▼───────────┐
            │  Internal Load        │
            │  Balancer (API:6443)  │
            └───────────────────────┘
```

## 🔧 Customization

### Change Instance Types

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
master_instance_type = "t3.large"
worker_instance_type = "t3.large"
```

### Change Number of Workers

```hcl
num_workers = 5
```

### Change Kubernetes Version

```hcl
kubernetes_version = "1.29.0"
```

### Change Network CIDRs

```hcl
vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
pod_cidr = "192.168.0.0/16"
service_cidr = "10.96.0.0/12"
```

## 🔐 Security

- **Bastion Access:** SSH only, configurable CIDR (default: 0.0.0.0/0)
- **Master Nodes:** Only accessible from workers and bastion
- **Worker Nodes:** Only accessible from masters and bastion
- **API Server:** Internal Load Balancer, not exposed to internet
- **Security Groups:** Least privilege principle applied

### Restrict Bastion Access

Edit `variables.tf`:

```hcl
bastion_allowed_cidr = "YOUR_IP/32"
```

## 📊 Monitoring

After deployment, you can:

1. **Check Node Status:**
   ```bash
   kubectl get nodes -o wide
   ```

2. **Check Pod Status:**
   ```bash
   kubectl get pods --all-namespaces
   ```

3. **Check Cluster Info:**
   ```bash
   kubectl cluster-info
   ```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**⚠️ Warning:** This will delete all resources including data!

## 🐛 Troubleshooting

### Master Node Not Ready

1. SSH to master node
2. Check kubelet status:
   ```bash
   sudo systemctl status kubelet
   sudo journalctl -u kubelet -f
   ```

3. Check containerd:
   ```bash
   sudo systemctl status containerd
   ```

### Worker Node Not Joining

1. Check join token is valid:
   ```bash
   # On master1
   kubeadm token list
   ```

2. Generate new token:
   ```bash
   kubeadm token create --print-join-command
   ```

### API Server Not Accessible

1. Check Load Balancer health:
   ```bash
   aws elbv2 describe-target-health --target-group-arn <tg-arn>
   ```

2. Check security groups allow port 6443

### Calico Not Working

Install manually:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

## 📝 Files Structure

```
k8s-ha-cluster/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables file
├── README.md                  # This file
├── modules/
│   ├── vpc/                   # VPC module
│   ├── ec2/                   # EC2 instance module
│   ├── security-groups/       # Security groups module
│   └── load-balancer/         # Load balancer module
└── cloud-init/
    ├── master-init.yaml       # First master node setup
    ├── master-join.yaml       # Additional master nodes
    ├── worker-join.yaml       # Worker nodes setup
    └── bastion.yaml           # Bastion host setup
```

## 🔄 How Automation Works

1. **VPC Creation:** Creates VPC with public/private subnets across AZs
2. **Load Balancers:** Creates internal API LB and public Ingress LB
3. **Master-1 Initialization:**
   - Installs containerd, kubeadm, kubelet, kubectl
   - Runs `kubeadm init` with API server endpoint
   - Installs Calico CNI
4. **Master-2 & Master-3:**
   - Install Kubernetes components
   - Join cluster using `kubeadm join --control-plane`
5. **Workers:**
   - Install Kubernetes components
   - Join cluster using `kubeadm join`
6. **Bastion:**
   - Installs kubectl and helper scripts
   - Ready for cluster management

## 💰 Cost Estimation

Approximate monthly costs (ap-southeast-1):

- 3x t3.medium masters: ~$90
- 2x t3.medium workers: ~$60
- 1x t3.micro bastion: ~$7
- 3x NAT Gateways: ~$135
- 2x Load Balancers: ~$35
- Data transfer: Variable

**Total: ~$327/month** (excluding data transfer)

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/about/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## ✅ Verification Checklist

After deployment, verify:

- [ ] All nodes show `Ready` status
- [ ] API server accessible via Load Balancer
- [ ] Calico pods running
- [ ] Can deploy test application
- [ ] Ingress Load Balancer accessible
- [ ] Bastion can access all nodes

## 🆘 Support

For issues:
1. Check logs: `kubectl logs <pod-name> -n <namespace>`
2. Check node status: `kubectl describe node <node-name>`
3. Review Terraform outputs: `terraform output`
4. Check AWS Console for resource status

---

**Created:** November 2024  
**Region:** ap-southeast-1 (Singapore)  
**Kubernetes Version:** 1.28.0  
**CNI:** Calico v3.26.1

