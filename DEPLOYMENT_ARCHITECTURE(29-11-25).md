# 🏗️ DhakaCart Deployment Architecture - সহজ ভাষায়

## 📊 Complete Flow

```
        👤 Users (Internet)
             │
             ▼
    ┌────────────────────┐
    │  Load Balancer     │ ◄── Public IP (Internet থেকে access)
    │  (ALB/ELB)         │
    └────────┬───────────┘
             │
    ┌────────▼───────────────────────────────────────────┐
    │              Private Network                       │
    │                                                     │
    │  ┌─────────────────────────────────────────┐     │
    │  │  Worker Nodes (Kubernetes)              │     │
    │  │                                          │     │
    │  │  ┌─────────────────────────────────┐   │     │
    │  │  │  DhakaCart Frontend Pods        │   │     │
    │  │  │  (React - 2-3 replicas)         │   │     │
    │  │  └─────────────────────────────────┘   │     │
    │  │                                          │     │
    │  │  ┌─────────────────────────────────┐   │     │
    │  │  │  DhakaCart Backend Pods         │   │     │
    │  │  │  (Node.js - 3-5 replicas)       │   │     │
    │  │  └─────────────────────────────────┘   │     │
    │  │                                          │     │
    │  │  ┌─────────────────────────────────┐   │     │
    │  │  │  Database Pod (PostgreSQL)      │   │     │
    │  │  └─────────────────────────────────┘   │     │
    │  │                                          │     │
    │  │  ┌─────────────────────────────────┐   │     │
    │  │  │  Redis Pod (Cache)              │   │     │
    │  │  └─────────────────────────────────┘   │     │
    │  └─────────────────────────────────────────┘     │
    │                                                     │
    │  Master Nodes (Control Plane - K8s management)    │
    └─────────────────────────────────────────────────────┘
```

---

## 🔍 Step by Step বোঝা যাক:

### 1️⃣ Infrastructure Layer (Terraform)

**এটা আপনি ইতিমধ্যে তৈরি করবেন:**

```
terraform/simple-k8s/
├── VPC, Subnets, Security Groups
├── Bastion Host (Public)
├── Master Nodes (Private)
└── Worker Nodes (Private)
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

### Phase 1: Infrastructure Setup

```bash
cd terraform/simple-k8s
terraform apply
# Output: Bastion IP, Master IPs, Worker IPs
```

### Phase 2: Kubernetes Installation

```bash
# 1. Bastion এ SSH
ssh -i key.pem ubuntu@BASTION_IP

# 2. Masters এ Kubernetes install (kubeadm)
ssh master-1
sudo kubeadm init

# 3. Workers কে join করানো
ssh worker-1
sudo kubeadm join ...
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

## 🔧 আপনার Current Setup এ যা Missing:

### ❌ Missing: Load Balancer

বর্তমানে আপনার Terraform এ Load Balancer নেই। Add করতে হবে:

```hcl
# main.tf এ add করুন

resource "aws_lb" "app" {
  name               = "dhakacart-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id, ...]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  name     = "dhakacart-targets"
  port     = 30080  # NodePort
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

---

## 📋 সম্পূর্ণ Deployment Checklist:

### ✅ Phase 1: Infrastructure
- [ ] Terraform apply (VPC, Subnets, EC2)
- [ ] Add Load Balancer
- [ ] Configure Security Groups

### ✅ Phase 2: Kubernetes
- [ ] Install kubeadm on all nodes
- [ ] Initialize master
- [ ] Join workers
- [ ] Install CNI (networking)

### ✅ Phase 3: Application
- [ ] Deploy Database (PostgreSQL)
- [ ] Deploy Redis
- [ ] Deploy Backend (Node.js)
- [ ] Deploy Frontend (React)

### ✅ Phase 4: Ingress/Load Balancer
- [ ] Install Ingress Controller
- [ ] Configure Ingress rules
- [ ] Test public access

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

1. **Load Balancer add করুন** Terraform এ
2. **Kubernetes install করুন** সব nodes এ
3. **Application deploy করুন** K8s cluster এ
4. **Test করুন** Load Balancer URL দিয়ে

প্রতিটা step এর জন্য আলাদা guide আছে `k8s/` folder এ।

