# 🚀 Complete Automation Plan - Kubernetes & AWS Integration

**তারিখ:** 2025-12-01  
**লক্ষ্য:** সম্পূর্ণ Automated Deployment - k8s + AWS + Terraform  
**LAB Practice:** ৪ ঘন্টা duration, Load Balancer URL changes every time

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Current Problems](#current-problems)
3. [Solution Architecture](#solution-architecture)
4. [Implementation Plan](#implementation-plan)
5. [Terraform Automation](#terraform-automation)
6. [Kubernetes Configuration](#kubernetes-configuration)
7. [Auto-Update Scripts](#auto-update-scripts)
8. [Complete Workflow](#complete-workflow)
9. [Files to Create/Update](#files-to-createupdate)

---

## Overview

### Goal
একটি সম্পূর্ণ automated system যেখানে:
- ✅ k8s files এ সব ports fixed/predefined
- ✅ Terraform automatically configure করে:
  - ALB Target Groups (Frontend + Backend)
  - ALB Listener Rules (Path-based routing)
  - Security Groups (NodePort access)
- ✅ `terraform apply` এর পর automatically:
  - Load Balancer URL extract করে
  - ConfigMap update করে
  - Frontend pods restart করে

### Benefits
- 🚀 **One Command Deployment**: `terraform apply` → Everything works
- 🔄 **LAB Friendly**: Load Balancer URL automatically updates
- ⚡ **Time Saving**: No manual AWS Console configuration
- 🛡️ **Error Free**: No manual mistakes

---

## Current Problems

### Problem 1: Manual Port Configuration
- ❌ Target Groups manually create করতে হয়
- ❌ Ports manually configure করতে হয় (30080, 30081)
- ❌ Worker nodes manually register করতে হয়

### Problem 2: Manual ALB Rules
- ❌ Path-based routing manually configure করতে হয়
- ❌ `/api*` → Backend rule manually add করতে হয়

### Problem 3: Manual Security Groups
- ❌ NodePort ports manually allow করতে হয়
- ❌ Load Balancer → Workers access manually configure করতে হয়

### Problem 4: Manual ConfigMap Update
- ❌ Load Balancer URL manually update করতে হয়
- ❌ Frontend pods manually restart করতে হয়
- ❌ LAB practice এ প্রতিবার URL change হলে manual update

---

## Solution Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Terraform Apply                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 1. Infrastructure (VPC, EC2, ALB)              │   │
│  │ 2. ALB Target Groups (Frontend + Backend)       │   │
│  │ 3. ALB Listener Rules (Path-based routing)      │   │
│  │ 4. Security Groups (NodePort access)            │   │
│  │ 5. Output: Load Balancer DNS                    │   │
│  └─────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              Post-Terraform Script                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 1. Extract Load Balancer URL from outputs       │   │
│  │ 2. Update k8s/configmaps/app-config.yaml        │   │
│  │ 3. Copy k8s/ files to Master-1                   │   │
│  │ 4. Apply k8s manifests on Master-1               │   │
│  │ 5. Update ConfigMap on cluster                   │   │
│  │ 6. Restart frontend pods                          │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Kubernetes Files - Fixed Ports ✅

**Status:** Already done!

**Files:**
- `k8s/services/services.yaml`
  - Frontend: NodePort `30080` ✅
  - Backend: NodePort `30081` ✅

**No changes needed** - ports are already fixed.

---

### Phase 2: Terraform - ALB Target Groups

**Create:** `terraform/simple-k8s/alb-target-groups.tf`

**What it does:**
- Creates Frontend Target Group (Port 30080)
- Creates Backend Target Group (Port 30081)
- Registers Worker Nodes automatically
- Configures Health Checks

---

### Phase 3: Terraform - ALB Listener Rules

**Create:** `terraform/simple-k8s/alb-listener-rules.tf`

**What it does:**
- Creates Listener Rule: `/api*` → Backend Target Group
- Sets Default Action: All others → Frontend Target Group
- Configures Path-based routing automatically

---

### Phase 4: Terraform - Security Groups Update

**Update:** `terraform/simple-k8s/security-groups.tf` (or create new)

**What it does:**
- Adds Inbound Rule: Allow TCP 30080 from ALB SG
- Adds Inbound Rule: Allow TCP 30081 from ALB SG
- Automatically configures worker nodes security group

---

### Phase 5: Terraform - Outputs

**Update:** `terraform/simple-k8s/outputs.tf`

**What it adds:**
- Load Balancer DNS name
- Frontend Target Group ARN
- Backend Target Group ARN
- Worker Node IPs (for reference)

---

### Phase 6: Post-Terraform Automation Script

**Create:** `terraform/simple-k8s/post-apply.sh`

**What it does:**
1. Extract Load Balancer URL from Terraform outputs
2. Update `k8s/configmaps/app-config.yaml` with LB URL
3. Copy k8s/ files to Master-1
4. Apply k8s manifests
5. Update ConfigMap on cluster
6. Restart frontend pods

---

## Terraform Automation

### File 1: `alb-target-groups.tf`

```terraform
# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name     = "${var.cluster_name}-frontend-tg"
  port     = 30080  # Fixed Frontend NodePort
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    port                = 30080
    matcher             = "200"
  }

  tags = {
    Name = "${var.cluster_name}-frontend-tg"
  }
}

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name     = "${var.cluster_name}-backend-tg"
  port     = 30081  # Fixed Backend NodePort
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"  # Or /api/health
    protocol            = "HTTP"
    port                = 30081
    matcher             = "200"
  }

  tags = {
    Name = "${var.cluster_name}-backend-tg"
  }
}

# Register Worker Nodes to Frontend Target Group
resource "aws_lb_target_group_attachment" "frontend" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = module.worker_nodes[count.index].instance_id
  port             = 30080
}

# Register Worker Nodes to Backend Target Group
resource "aws_lb_target_group_attachment" "backend" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = module.worker_nodes[count.index].instance_id
  port             = 30081
}
```

---

### File 2: `alb-listener-rules.tf`

```terraform
# ALB Listener (Port 80)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Listener Rule: /api* → Backend
resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api*"]
    }
  }
}
```

---

### File 3: `security-groups-alb.tf` (Update existing)

```terraform
# Security Group Rule: Allow NodePort 30080 from ALB
resource "aws_security_group_rule" "worker_frontend_nodeport" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = module.worker_nodes[0].security_group_id  # Worker SG
  description              = "Allow Frontend NodePort from ALB"
}

# Security Group Rule: Allow NodePort 30081 from ALB
resource "aws_security_group_rule" "worker_backend_nodeport" {
  type                     = "ingress"
  from_port                = 30081
  to_port                  = 30081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = module.worker_nodes[0].security_group_id  # Worker SG
  description              = "Allow Backend NodePort from ALB"
}
```

---

### File 4: Update `outputs.tf`

```terraform
# Load Balancer DNS
output "load_balancer_dns" {
  description = "Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

# Frontend Target Group ARN
output "frontend_target_group_arn" {
  description = "Frontend Target Group ARN"
  value       = aws_lb_target_group.frontend.arn
}

# Backend Target Group ARN
output "backend_target_group_arn" {
  description = "Backend Target Group ARN"
  value       = aws_lb_target_group.backend.arn
}

# Worker Node IPs
output "worker_node_ips" {
  description = "Worker Node Private IPs"
  value       = [for node in module.worker_nodes : node.private_ip]
}
```

---

## Kubernetes Configuration

### Current Status ✅

**Files already configured:**
- `k8s/services/services.yaml`
  - Frontend: NodePort `30080` ✅
  - Backend: NodePort `30081` ✅

**No changes needed** - ports are fixed!

---

## Auto-Update Scripts

### Script 1: `post-apply.sh`

**Location:** `terraform/simple-k8s/post-apply.sh`

**Purpose:** Run after `terraform apply` to automatically:
1. Extract Load Balancer URL
2. Update ConfigMap
3. Deploy k8s manifests
4. Restart pods

**Usage:**
```bash
cd terraform/simple-k8s
terraform apply
./post-apply.sh
```

---

### Script 2: `update-configmap-auto.sh`

**Location:** `terraform/simple-k8s/update-configmap-auto.sh`

**Purpose:** Extract LB URL from Terraform and update ConfigMap

**Usage:**
```bash
./update-configmap-auto.sh
```

---

## Complete Workflow

### Step 1: Initial Setup (One Time)

```bash
# 1. Navigate to Terraform directory
cd terraform/simple-k8s

# 2. Initialize Terraform
terraform init

# 3. Review variables
cat terraform.tfvars
```

---

### Step 2: Deploy Infrastructure

```bash
# 1. Apply Terraform (creates everything)
terraform apply

# 2. Run post-apply script (auto-updates everything)
./post-apply.sh
```

**What happens:**
- ✅ Infrastructure created
- ✅ ALB Target Groups created
- ✅ ALB Listener Rules configured
- ✅ Security Groups updated
- ✅ Load Balancer URL extracted
- ✅ ConfigMap updated
- ✅ k8s manifests applied
- ✅ Frontend pods restarted

---

### Step 3: Verify

```bash
# Get Load Balancer URL
terraform output load_balancer_dns

# Test in browser
# http://<load-balancer-dns>
```

---

## Files to Create/Update

### New Files to Create:

1. **`terraform/simple-k8s/alb-target-groups.tf`**
   - Frontend Target Group (Port 30080)
   - Backend Target Group (Port 30081)
   - Target Group Attachments

2. **`terraform/simple-k8s/alb-listener-rules.tf`**
   - ALB Listener (Port 80)
   - Path-based routing rules

3. **`terraform/simple-k8s/security-groups-alb.tf`**
   - NodePort security group rules

4. **`terraform/simple-k8s/post-apply.sh`**
   - Complete automation script

5. **`terraform/simple-k8s/update-configmap-auto.sh`**
   - ConfigMap auto-update script

### Files to Update:

1. **`terraform/simple-k8s/outputs.tf`**
   - Add Load Balancer DNS output
   - Add Target Group ARNs

2. **`terraform/simple-k8s/main.tf`** (if needed)
   - Reference new resources

---

## Implementation Steps

### Step 1: Create Terraform Files

1. Create `alb-target-groups.tf`
2. Create `alb-listener-rules.tf`
3. Create `security-groups-alb.tf`
4. Update `outputs.tf`

### Step 2: Create Automation Scripts

1. Create `post-apply.sh`
2. Create `update-configmap-auto.sh`
3. Make scripts executable

### Step 3: Test

1. `terraform plan` - Review changes
2. `terraform apply` - Deploy infrastructure
3. `./post-apply.sh` - Auto-configure k8s
4. Verify in browser

---

## Benefits

### Before (Manual):
- ⏱️ 30-45 minutes manual configuration
- ❌ Error-prone
- ❌ Repetitive work
- ❌ LAB practice এ প্রতিবার same steps

### After (Automated):
- ⚡ 5-10 minutes total
- ✅ Zero manual configuration
- ✅ Error-free
- ✅ One command: `terraform apply && ./post-apply.sh`

---

## LAB Practice Workflow

### Every Time (4-hour LAB):

```bash
# 1. Deploy everything
cd terraform/simple-k8s
terraform apply

# 2. Auto-configure (one command)
./post-apply.sh

# 3. Done! Website works!
```

**That's it!** No manual steps needed.

---

## Troubleshooting

### Issue: Target Groups Not Created

**Check:**
- Terraform apply completed successfully?
- Worker nodes exist?
- VPC ID correct?

### Issue: ConfigMap Not Updated

**Check:**
- Load Balancer DNS in outputs?
- Script has correct paths?
- Master-1 accessible?

### Issue: ALB Rules Not Working

**Check:**
- Listener rules priority correct?
- Path pattern correct (`/api*`)?
- Target groups healthy?

---

## Next Steps

1. ✅ Review this plan
2. ✅ Create Terraform files (alb-target-groups.tf, etc.)
3. ✅ Create automation scripts
4. ✅ Test complete workflow
5. ✅ Document any issues

---

**Created:** 2025-12-01 
**Status:** Planning Complete - Ready for Implementation ✅  
**Estimated Implementation Time:** 2-3 hours  
**Estimated Deployment Time:** 5-10 minutes (after automation)

---

## Summary

এই plan অনুযায়ী implementation করলে:

- ✅ **k8s files:** Ports already fixed (30080, 30081)
- ✅ **Terraform:** Automatically creates Target Groups, ALB Rules, Security Groups
- ✅ **Post-Apply:** Automatically updates ConfigMap and deploys k8s
- ✅ **LAB Practice:** One command deployment (`terraform apply && ./post-apply.sh`)

**Result:** সম্পূর্ণ automated, zero manual configuration! 🚀

