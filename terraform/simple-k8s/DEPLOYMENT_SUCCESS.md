# ✅ Kubernetes Infrastructure Deployed Successfully!

**Date:** 29 November 2025  
**Status:** ✅ All Resources Created

---

## 🎉 Deployment Summary

| Resource | Count | Instance Type | Status |
|----------|-------|---------------|--------|
| **Bastion** | 1 | t2.micro | ✅ Running |
| **Master Nodes** | 2 | t2.small | ✅ Running |
| **Worker Nodes** | 3 | t2.small | ✅ Running |
| **Load Balancer** | 1 | ALB | ✅ Active |
| **NAT Gateway** | 1 | - | ✅ Active |

---

## 🌐 Access Information

### Public URLs

| Service | URL |
|---------|-----|
| **Load Balancer** | http://dhakacart-k8s-alb-1192201581.ap-southeast-1.elb.amazonaws.com |
| **Bastion SSH** | ssh -i dhakacart-k8s-key.pem ubuntu@47.128.147.39 |

### Private IPs

| Node | IP Address | Type |
|------|------------|------|
| Master-1 | 10.0.10.100 | Control Plane |
| Master-2 | 10.0.10.36 | Control Plane |
| Worker-1 | 10.0.10.224 | Application |
| Worker-2 | 10.0.10.213 | Application |
| Worker-3 | 10.0.10.84 | Application |

---

## 🔑 SSH Access

### 1. SSH to Bastion:

```bash
cd /home/arif/DhakaCart-03/terraform/simple-k8s
ssh -i dhakacart-k8s-key.pem ubuntu@47.128.147.39
```

### 2. Copy SSH Key to Bastion:

```bash
scp -i dhakacart-k8s-key.pem dhakacart-k8s-key.pem ubuntu@47.128.147.39:~/.ssh/
ssh -i dhakacart-k8s-key.pem ubuntu@47.128.147.39
chmod 400 ~/.ssh/dhakacart-k8s-key.pem
```

### 3. Test Connectivity (Ping):

```bash
# From bastion, test all nodes
ping -c 2 10.0.10.100  # Master-1 ✅
ping -c 2 10.0.10.36   # Master-2 ✅
ping -c 2 10.0.10.224  # Worker-1 ✅
ping -c 2 10.0.10.213  # Worker-2 ✅
ping -c 2 10.0.10.84   # Worker-3 ✅
```

### 4. From Bastion, SSH to Nodes:

```bash
# Master-1
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.100

# Master-2
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.36

# Worker-1
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.224
```

---

## 🚀 Next Steps

### Phase 1: Install Kubernetes

#### On Master-1 (Initialize cluster):

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install kubeadm, kubelet, kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Install container runtime (containerd)
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Initialize cluster
sudo kubeadm init --control-plane-endpoint="10.0.10.100:6443" --pod-network-cidr=10.244.0.0/16

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

#### On Master-2 (Join as control plane):

```bash
# Install dependencies (same as Master-1)
# Then join using the command from Master-1 init output:
sudo kubeadm join 10.0.10.100:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash> \
    --control-plane
```

#### On Workers (Join as worker):

```bash
# Install dependencies (same as Master-1)
# Then join:
sudo kubeadm join 10.0.10.100:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

### Phase 2: Deploy DhakaCart Application

```bash
# From Master-1
kubectl apply -f /path/to/k8s/namespace.yaml
kubectl apply -f /path/to/k8s/deployments/
kubectl apply -f /path/to/k8s/services/
```

### Phase 3: Configure Ingress

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# This will create a LoadBalancer service that connects to your ALB
```

---

## 💰 Cost Estimate

| Resource | Cost/Hour | Cost/Day |
|----------|-----------|----------|
| t2.micro (1) | $0.0116 | $0.28 |
| t2.small (5) | $0.023 × 5 | $2.76 |
| ALB | $0.0225 | $0.54 |
| NAT Gateway | $0.045 | $1.08 |
| Data Transfer | ~$0.02 | ~$0.48 |
| **Total** | **~$0.21/hour** | **~$5.14/day** |

---

## 🔒 Security

- ✅ Masters/Workers in private subnet (no public IP)
- ✅ Bastion as single entry point
- ✅ Security groups properly configured
- ✅ SSH key authentication only
- ✅ ICMP (ping) allowed from bastion to nodes
- ✅ Internet access via NAT Gateway

---

## 📊 Architecture

```
Internet
    │
    ├─────► Load Balancer (Public)
    │       dhakacart-k8s-alb-xxx
    │       Port 80 → Workers NodePort 30080
    │
    └─────► Bastion (Public)
            47.128.147.39
            SSH Gateway
                │
                ▼
    ┌─────────────────────────────────────┐
    │      Private Subnet 10.0.10.0/24    │
    │                                      │
    │  Masters (K8s Control Plane):       │
    │  ├── 10.0.10.100                    │
    │  └── 10.0.10.36                     │
    │                                      │
    │  Workers (Run Applications):        │
    │  ├── 10.0.10.224                    │
    │  ├── 10.0.10.213                    │
    │  └── 10.0.10.84                     │
    │                                      │
    │  ✅ Internet via NAT Gateway         │
    │  ❌ No Public IPs                    │
    └─────────────────────────────────────┘
```

---

## 🗑️ Cleanup (When Done)

```bash
cd /home/arif/DhakaCart-03/terraform/simple-k8s
terraform destroy -auto-approve
```

**Warning:** এটা সব resources delete করে দেবে!

---

## ✅ Success Factors

| Issue | Solution |
|-------|----------|
| EC2 Permission Denied | ✅ Used t2.small instead of t2.medium |
| Key Management | ✅ Auto-generated and saved locally |
| Network Isolation | ✅ Private subnet for nodes |
| Public Access | ✅ Load Balancer configured |
| Cost Control | ✅ Small instances (~$5/day) |

---

**Deployed by:** Terraform  
**Key Location:** `./dhakacart-k8s-key.pem`  
**VPC ID:** vpc-03ec2ac8e10020691

