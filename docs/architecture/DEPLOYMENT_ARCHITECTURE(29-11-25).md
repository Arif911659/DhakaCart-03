# 🏗️ DhakaCart Deployment Architecture - সহজ ভাষায়

**Status:** ✅ Infrastructure Deployed (29 Nov 2025)  
**Location:** `terraform/simple-k8s/`

## 📊 Deployed Infrastructure

| Resource | Count | Type | IP/DNS | Status |
|----------|-------|------|--------|--------|
| **Bastion** | 1 | t2.micro | 47.128.147.39 | ✅ Running |
| **Masters** | 2 | t2.small | 10.0.10.100, 10.0.10.36 | ✅ Running |
| **Workers** | 3 | t2.small | 10.0.10.224, 213, 84 | ✅ Running |
| **Load Balancer** | 1 | ALB | dhakacart-k8s-alb-1192201581... | ✅ Active |

---

## 📊 Complete Flow

```
        👤 Users (Internet)
             │
             ▼
    ┌─────────────────────────────────────────┐
    │  AWS Load Balancer (ALB) - PUBLIC       │
    │  dhakacart-k8s-alb-1192201581...        │ ✅ DEPLOYED
    │  Port 80 → NodePort 30080               │
    └────────┬────────────────────────────────┘
             │
    ┌────────▼──────────────────────────────────────────────┐
    │         VPC: 10.0.0.0/16                              │
    │                                                        │
    │  Public Subnet (10.0.1.0/24):                        │
    │  ┌──────────────────────────────┐                    │
    │  │  🔑 Bastion (47.128.147.39)  │ ✅ SSH from anywhere│
    │  │  t2.micro                     │                    │
    │  └──────────────┬───────────────┘                    │
    │                 │ SSH                                 │
    │                 │                                     │
    │  Private Subnet (10.0.10.0/24): │                    │
    │  ┌──────────────▼───────────────────────────┐       │
    │  │  📊 Masters (K8s Control Plane):         │       │
    │  │  ├─ Master-1: 10.0.10.100 (t2.small)     │ ✅    │
    │  │  └─ Master-2: 10.0.10.36  (t2.small)     │ ✅    │
    │  │                                           │       │
    │  │  🎯 Workers (Run DhakaCart Pods):        │       │
    │  │  ├─ Worker-1: 10.0.10.224 (t2.small)     │ ✅    │
    │  │  ├─ Worker-2: 10.0.10.213 (t2.small)     │ ✅    │
    │  │  └─ Worker-3: 10.0.10.84  (t2.small)     │ ✅    │
    │  │                                           │       │
    │  │  When DhakaCart deployed:                │       │
    │  │  ┌─────────────────────────────────┐    │       │
    │  │  │  Frontend Pods (React)          │    │       │
    │  │  │  Backend Pods (Node.js)         │    │       │
    │  │  │  Database Pod (PostgreSQL)      │    │       │
    │  │  │  Redis Pod (Cache)              │    │       │
    │  │  └─────────────────────────────────┘    │       │
    │  │                                           │       │
    │  │  ✅ Internet via NAT Gateway             │       │
    │  │  ❌ No Public IPs                        │       │
    │  └───────────────────────────────────────────┘       │
    └──────────────────────────────────────────────────────┘
```
## Updated Checklist:
✅ Phase 1: Infrastructure (COMPLETED)
   ✅ Terraform apply
   ✅ Load Balancer configured
   ✅ Security Groups
   ✅ ICMP (ping) enabled
   ✅ Connectivity tested

⏳ Phase 2: Kubernetes (NEXT STEP)
   □ Install kubeadm
   □ Initialize master-1
   □ Join nodes

⏳ Phase 3: Application
   □ Deploy DhakaCart

⏳ Phase 4: Public Access
   □ Configure Ingress

---

## 🔍 Step by Step বোঝা যাক:

### 1️⃣ Infrastructure Layer (Terraform) ✅ COMPLETED

**Status:** ✅ Successfully deployed with t2.small instances

```
terraform/simple-k8s/
├── VPC: vpc-03ec2ac8e10020691
├── Subnets: Public (10.0.1.0/24, 10.0.2.0/24), Private (10.0.10.0/24)
├── Bastion: 47.128.147.39 (t2.micro, Public)
├── Masters: 10.0.10.100, 10.0.10.36 (2x t2.small, Private)
├── Workers: 10.0.10.224, 213, 84 (3x t2.small, Private)
├── Load Balancer: dhakacart-k8s-alb-1192201581...
├── NAT Gateway: For internet access
└── SSH Key: dhakacart-k8s-key.pem (auto-generated)
```

**Deploy Command:**
```bash
cd terraform/simple-k8s
terraform apply  # ✅ Done!
```

### 2️⃣ Kubernetes Layer

**Master Nodes এ install হবে:**
- Kubernetes Control Plane (API Server, Scheduler, etc.)
- কাজ: Cluster manage করা

**Worker Nodes এ install হবে:**
- Kubernetes Worker (kubelet, container runtime)
- কাজ: Application pods চালানো

### 3️⃣ Application Layer (Your DhakaCart)

**Worker Nodes এ deploy হবে Kubernetes Pods হিসেবে:**

```yaml
Worker Node 1:
  - Frontend Pod (1-2 replicas)
  - Backend Pod (1-2 replicas)
  
Worker Node 2:
  - Frontend Pod (1-2 replicas)
  - Backend Pod (1-2 replicas)
  
Worker Node 3:
  - Database Pod
  - Redis Pod
```

### 4️⃣ Load Balancer (Public Access)

**Terraform এ add করতে হবে:**

```hcl
AWS Application Load Balancer (ALB)
├── Public Subnet এ
├── Public IP পাবে
└── Worker Nodes এর frontend pods এ forward করবে
```

---

## 🚀 Deployment Steps (পুরো Process)

### Phase 1: Infrastructure Setup ✅ COMPLETED

```bash
cd terraform/simple-k8s
terraform apply  # ✅ Done!

# Outputs:
Bastion IP:      47.128.147.39
Load Balancer:   http://dhakacart-k8s-alb-1192201581.ap-southeast-1.elb.amazonaws.com
Masters:         10.0.10.100, 10.0.10.36
Workers:         10.0.10.224, 10.0.10.213, 10.0.10.84
SSH Key:         dhakacart-k8s-key.pem
```

### Phase 2: Kubernetes Installation ⏳ NEXT STEP

```bash
# 1. SSH to Bastion
ssh -i dhakacart-k8s-key.pem ubuntu@47.128.147.39

# 2. Copy SSH key to bastion
scp -i dhakacart-k8s-key.pem dhakacart-k8s-key.pem ubuntu@47.128.147.39:~/.ssh/
chmod 400 ~/.ssh/dhakacart-k8s-key.pem

# 3. Test connectivity (from bastion)
ping -c 2 10.0.10.100  # Master-1 ✅
ping -c 2 10.0.10.224  # Worker-1 ✅

# 4. SSH to Master-1 (from bastion)
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.100

# 5. Install Kubernetes on Master-1
sudo kubeadm init --control-plane-endpoint="10.0.10.100:6443"

# 6. Join other nodes
# (Run join commands on Master-2 and Workers)
```

### Phase 3: Application Deployment

```bash
# Kubernetes cluster থেকে
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
kubectl apply -f k8s/ingress/
```

### Phase 4: Ingress/Load Balancer Setup

```bash
# NGINX Ingress Controller install
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# এটা automatically একটা AWS Load Balancer তৈরি করবে
```

---

## 🌐 Public Access কিভাবে হবে?

### বর্তমান Flow:

```
1. User browser এ type করবে: http://LOAD_BALANCER_DNS

2. Load Balancer (Public IP) request receive করবে

3. Load Balancer forward করবে → Worker Nodes এর Frontend Pods

4. Frontend → Backend Pods (API calls)

5. Backend → Database/Redis Pods

6. Response flow reverse হবে User পর্যন্ত
```

### Example URL:

```
http://dhakacart-alb-123456789.ap-southeast-1.elb.amazonaws.com
                    ↓
            AWS Load Balancer (Public)
                    ↓
          Worker Nodes (Private)
                    ↓
        DhakaCart Frontend/Backend Pods
```

---

## ✅ Current Infrastructure Status:

### Load Balancer Configuration

```hcl
# ✅ Already deployed in main.tf

resource "aws_lb" "app" {
  name               = "dhakacart-k8s-alb"  ✅
  load_balancer_type = "application"
  subnets            = [public_1, public_2]
  security_groups    = [alb_sg]
}

DNS: dhakacart-k8s-alb-1192201581.ap-southeast-1.elb.amazonaws.com
Target: Worker nodes on port 30080 (Ingress NodePort)
```

### Network Connectivity Test Results:

| From | To | Protocol | Result |
|------|-----|----------|--------|
| Bastion | Master-1 | ICMP (ping) | ✅ 0.2-0.7ms |
| Bastion | Master-2 | ICMP (ping) | ✅ 0.6-1.7ms |
| Bastion | Worker-1 | ICMP (ping) | ✅ 1.1-2.3ms |
| Bastion | Worker-2 | ICMP (ping) | ✅ 1.8-2.0ms |
| Bastion | Worker-3 | ICMP (ping) | ✅ 0.2-2.2ms |
| Bastion | All nodes | SSH (22) | ✅ Working |
| ALB | Workers | HTTP (30080) | ⏳ Pending K8s |
| Private nodes | Internet | NAT Gateway | ✅ Available |

---

## 📋 সম্পূর্ণ Deployment Checklist:

### ✅ Phase 1: Infrastructure (COMPLETED)
- [x] Terraform apply (VPC, Subnets, EC2) ✅
- [x] Add Load Balancer ✅
- [x] Configure Security Groups ✅
- [x] Enable ICMP (ping) from bastion ✅
- [x] Test connectivity ✅

### ⏳ Phase 2: Kubernetes (NEXT)
- [ ] Install kubeadm on all nodes
- [ ] Initialize master-1
- [ ] Join master-2 to cluster
- [ ] Join workers to cluster
- [ ] Install CNI (Flannel/Calico)
- [ ] Verify cluster: `kubectl get nodes`

### ⏳ Phase 3: Application
- [ ] Deploy Database (PostgreSQL)
- [ ] Deploy Redis
- [ ] Deploy Backend (Node.js)
- [ ] Deploy Frontend (React)
- [ ] Configure environment variables

### ⏳ Phase 4: Ingress/Load Balancer
- [ ] Install NGINX Ingress Controller
- [ ] Configure Ingress with NodePort 30080
- [ ] Test: http://dhakacart-k8s-alb-1192201581...
- [ ] Verify end-to-end access

---

## 🎯 Simple Summary:

| Where | What | Public Access |
|-------|------|---------------|
| **Bastion** | SSH gateway | ✅ Yes (for admin) |
| **Masters** | K8s control plane | ❌ No |
| **Workers** | Run your application | ❌ No (directly) |
| **Load Balancer** | Public entry point | ✅ Yes (for users) |

**মূল কথা:**
- Application = Worker nodes এ pods হিসেবে চলবে
- Public Access = Load Balancer দিয়ে হবে
- Admin Access = Bastion দিয়ে হবে

---

## 🔍 Next Steps:

### ✅ Completed:
1. ✅ Infrastructure deployed (Terraform)
2. ✅ Load Balancer configured
3. ✅ Connectivity verified (ping, SSH)

### ⏳ TODO:
1. **Install Kubernetes** on all 5 nodes
2. **Deploy DhakaCart** application
3. **Test public access** via Load Balancer URL

### 🚀 Start Here:

```bash
# SSH to bastion
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@47.128.147.39

# Copy key
scp -i terraform/simple-k8s/dhakacart-k8s-key.pem \
    terraform/simple-k8s/dhakacart-k8s-key.pem \
    ubuntu@47.128.147.39:~/.ssh/

# Test ping
ping 10.0.10.100  # Master-1 ✅

# SSH to master
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.100
```

---

## 💰 Current Cost: ~$5/day

---

**Updated:** 29 November 2025  
**Documentation:** `terraform/simple-k8s/DEPLOYMENT_SUCCESS.md`

