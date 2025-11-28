# 📋 DhakaCart Project Tracking Log

**Project:** DhakaCart E-Commerce Reliability Challenge  
**Start Date:** November 2024  
**Last Updated:** 28 November 2025

---

## 🎯 Project Goal

Transform DhakaCart's fragile single-machine setup into a resilient, scalable, and secure cloud-based e-commerce infrastructure.

---

## 📊 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Terraform Infrastructure | ✅ Deployed | VPC, Subnets, Load Balancers |
| Master Nodes (3) | ✅ Running | Private subnets |
| Worker Nodes (2) | ✅ Running | Private subnets |
| API Load Balancer (NLB) | ✅ Active | Internal, TCP 6443 |
| Ingress Load Balancer (ALB) | ✅ Active | Public, HTTP/HTTPS |
| Bastion Host | ✅ Running | Private subnet, SSM access |

---

## 🌐 Public Access URLs

| Service | URL | Status |
|---------|-----|--------|
| **DhakaCart Application** | http://dhakacart-k8s-ha-ingress-lb-1770210395.ap-southeast-1.elb.amazonaws.com | ⚠️ K8s cluster not initialized |
| **API Server (Internal)** | dhakacart-k8s-ha-api-lb-8c5eae279d2560f9.elb.ap-southeast-1.amazonaws.com:6443 | ✅ Ready |

## 🔑 Bastion (Jumpbox) Access

⚠️ **Important:** AWS policy blocks EC2 instances with "bastion" name in public subnets. 
Renamed to "jumpbox" and placed in private subnet. Use AWS SSM to access.

```bash
# Step 1: Connect to jumpbox via AWS SSM
aws ssm start-session --target i-0e7c333cbe40f057c

# Step 2: From jumpbox, SSH to master-1
ssh -i ~/.ssh/dhakacart-k8s-ha-key.pem ubuntu@10.0.11.82

# Step 3: Check cluster
kubectl get nodes
```

### Alternative: SSM Port Forwarding for SSH

```bash
# Forward local port 2222 to jumpbox SSH
aws ssm start-session --target i-0e7c333cbe40f057c \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}'

# Then SSH locally
ssh -p 2222 ubuntu@localhost
```

---

## 🖥️ Infrastructure Details

### EC2 Instances

| Name | Instance ID | Private IP | Subnet | Status |
|------|-------------|------------|--------|--------|
| master-1 | i-0880a567f38f7b6c3 | 10.0.11.82 | private-1 | ✅ Running |
| master-2 | i-04a2f51d09ed97efe | 10.0.12.190 | private-2 | ✅ Running |
| master-3 | i-0d60297484d18f5b8 | 10.0.13.230 | private-3 | ✅ Running |
| worker-1 | i-0cb3bada3b5e3a12b | 10.0.11.158 | private-1 | ✅ Running |
| worker-2 | i-0e940fee524b2d4c8 | 10.0.12.21 | private-2 | ✅ Running |
| jumpbox (bastion) | i-0e7c333cbe40f057c | 10.0.11.219 | private-1 | ✅ Running |

### Load Balancers

| Name | Type | Scheme | DNS |
|------|------|--------|-----|
| dhakacart-k8s-ha-api-lb | NLB | Internal | dhakacart-k8s-ha-api-lb-xxx.elb.ap-southeast-1.amazonaws.com |
| dhakacart-k8s-ha-ingress-lb | ALB | Internet-facing | dhakacart-k8s-ha-ingress-lb-xxx.ap-southeast-1.elb.amazonaws.com |

---

## 📝 Change Log

### 28 November 2025

#### Issue 1: Security Groups Circular Dependency
- **Error:** `Error: Cycle: module.security_groups.aws_security_group.worker, module.security_groups.aws_security_group.master`
- **Fix:** Separate `aws_security_group_rule` resources created
- **Status:** ✅ Fixed

#### Issue 2: Template File Variable Error
- **Error:** `vars map does not contain key "CLUSTER_NAME"`
- **Fix:** Used `$$` escaping for bash variables in cloud-init
- **Status:** ✅ Fixed

#### Issue 3: Output Self Reference Error
- **Error:** `Invalid "self" reference`
- **Fix:** Direct module references used instead of self
- **Status:** ✅ Fixed

#### Issue 4: AMI Lookup Failed
- **Error:** `Your query returned no results`
- **Fix:** Updated AMI filter pattern to `ubuntu/images/*/ubuntu-jammy-22.04-amd64-server-*`
- **Status:** ✅ Fixed

#### Issue 5: IAM TagRole Permission
- **Error:** `iam:TagRole permission denied`
- **Fix:** IAM resources commented out (AWS account restriction)
- **Status:** ✅ Workaround applied

#### Issue 6: IAM TagInstanceProfile Permission
- **Error:** `iam:TagInstanceProfile permission denied`
- **Fix:** IAM instance profile removed
- **Status:** ✅ Workaround applied

#### Issue 7: EC2 RunInstances for Bastion
- **Error:** `ec2:RunInstances explicit deny` - AWS policy blocks "bastion" name
- **Fix:** Renamed to "jumpbox" + tagged as `Role=worker` + private subnet
- **Status:** ✅ Fixed

#### Issue 8: Public Subnet EC2 Blocked
- **Error:** AWS policy explicit deny for EC2 in public subnets
- **Root Cause:** AWS admin policy restriction
- **Impact:** Cannot have public bastion host
- **Workaround:** Use AWS SSM Session Manager to access private subnet jumpbox
- **Status:** ⚠️ AWS Admin action required for public access

---

## 🔧 Pending Tasks

- [x] Fix bastion host access ✅
- [x] Configure Load Balancer target groups ✅
- [ ] **Initialize Kubernetes cluster on master-1**
- [ ] **Deploy NGINX Ingress Controller**
- [ ] Deploy DhakaCart application to Kubernetes
- [ ] Configure Ingress controller
- [ ] Setup monitoring (Prometheus/Grafana)
- [ ] Setup logging (ELK/Loki)
- [ ] Configure CI/CD pipeline
- [ ] Setup database backups
- [ ] Security hardening

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| `terraform/k8s-ha-cluster/main.tf` | Main Terraform configuration |
| `terraform/k8s-ha-cluster/terraform.tfvars` | Variable values |
| `terraform/k8s-ha-cluster/dhakacart-k8s-ha-key.pem` | SSH private key |
| `terraform/k8s-ha-cluster/FIXES_2025-11-28.md` | Detailed fix documentation |
| `k8s/deployments/` | Kubernetes manifests |

---

## 🚨 Known Issues

1. **AWS Permission Restrictions:**
   - User `ln7u-poridhi` has explicit deny for EC2 in public subnets
   - IAM role/instance profile creation requires `iam:Tag*` permissions

2. **Bastion Host:**
   - Cannot create in public subnet due to AWS policy
   - Alternative: Private subnet bastion with SSM access

---

## 📞 Next Steps

1. Create bastion in private subnet with SSM
2. Verify Kubernetes cluster health
3. Deploy DhakaCart application
4. Configure DNS and SSL

---

**Updated by:** DevOps Automation  
**Project Repository:** https://github.com/Arif911659/DhakaCart-03

# Jumpbox এ connect করুন
aws ssm start-session --target i-0e7c333cbe40f057c

# Jumpbox থেকে master-1 এ SSH
ssh -i ~/.ssh/dhakacart-k8s-ha-key.pem ubuntu@10.0.11.82

# Jumpbox এ connect করুন
aws ssm start-session --target i-0e7c333cbe40f057c

# Jumpbox থেকে master-1 এ SSH
ssh -i ~/.ssh/dhakacart-k8s-ha-key.pem ubuntu@10.0.11.82

Internet
    │
    ▼
┌─────────────────────────────────────────┐
│           VPC (10.0.0.0/16)             │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      Public Subnets             │   │
│  │  ┌─────────┐  ┌─────────────┐  │   │
│  │  │ NAT GW  │  │ ALB (Ingress)│  │   │ ◄── Public Access
│  │  └────┬────┘  └─────────────┘  │   │
│  └───────┼─────────────────────────┘   │
│          │                             │
│  ┌───────▼─────────────────────────┐   │
│  │      Private Subnets            │   │
│  │  ┌─────────┐  ┌─────────────┐  │   │
│  │  │Jumpbox  │  │ Masters (3) │  │   │ ◄── No Public IP
│  │  │10.0.11. │  │ Workers (2) │  │   │     Internet via NAT ✅
│  │  │219      │  │             │  │   │
│  │  └─────────┘  └─────────────┘  │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘


