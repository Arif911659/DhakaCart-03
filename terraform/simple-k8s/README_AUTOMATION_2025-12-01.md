# 🚀 Complete Automation Guide - Terraform + Kubernetes

**তারিখ:** 2025-12-01  
**লক্ষ্য:** One-Command Deployment - `terraform apply && ./post-apply.sh`

---

## 📋 Overview

এই automation system আপনাকে দেবে:
- ✅ **Fixed Ports**: k8s files এ সব ports predefined (30080, 30081)
- ✅ **Auto Target Groups**: Terraform automatically creates Frontend + Backend target groups
- ✅ **Auto ALB Rules**: Path-based routing (`/api*` → Backend) automatically configured
- ✅ **Auto Security Groups**: NodePort access automatically allowed
- ✅ **Auto ConfigMap Update**: Load Balancer URL automatically updates
- ✅ **One Command**: `terraform apply && ./post-apply.sh` → Everything works!

---

## 🎯 What's Automated

### 1. Terraform Infrastructure ✅

**File:** `alb-backend-config.tf`

**Creates:**
- Backend Target Group (Port 30081)
- Backend Target Group Attachments (Worker nodes)
- ALB Listener Rule (`/api*` → Backend)

**Existing (in main.tf):**
- Frontend Target Group (Port 30080) ✅
- ALB Listener (Port 80) ✅
- Security Groups (NodePort access) ✅

---

### 2. Post-Apply Automation ✅

**File:** `post-apply.sh`

**Does:**
1. Extracts Load Balancer URL from Terraform outputs
2. Updates `k8s/configmaps/app-config.yaml` with LB URL
3. Copies k8s/ files to Master-1
4. Applies all k8s manifests
5. Updates ConfigMap on cluster
6. Restarts frontend pods

---

## 🚀 Usage

### Complete Deployment (One Command)

```bash
cd terraform/simple-k8s

# Deploy everything
terraform apply && ./post-apply.sh
```

**That's it!** Website will be accessible after 2-3 minutes.

---

### Step-by-Step (If Needed)

```bash
# Step 1: Deploy infrastructure
terraform apply

# Step 2: Run automation
./post-apply.sh
```

---

## 📁 Files Structure

```
terraform/simple-k8s/
├── main.tf                    # Existing infrastructure
├── alb-backend-config.tf      # NEW: Backend target group + ALB rules
├── outputs.tf                 # UPDATED: Added target group ARNs
├── post-apply.sh              # NEW: Complete automation
└── update-configmap-auto.sh  # NEW: ConfigMap update only

k8s/
├── services/services.yaml     # ✅ Fixed ports (30080, 30081)
├── configmaps/app-config.yaml # ✅ Template with LB URL placeholder
└── AUTOMATION_PLAN_2024-11-30.md  # Complete plan document
```

---

## 🔧 Configuration

### Fixed Ports (Already Configured)

**Frontend Service:**
- Service Port: `80`
- Target Port: `3000` (container)
- NodePort: `30080` ✅ Fixed

**Backend Service:**
- Service Port: `5000`
- Target Port: `5000` (container)
- NodePort: `30081` ✅ Fixed

---

### Terraform Resources

**Frontend Target Group:**
- Port: `30080`
- Health Check: `/` on port `30080`
- Targets: All worker nodes

**Backend Target Group:**
- Port: `30081`
- Health Check: `/health` on port `30081`
- Targets: All worker nodes

**ALB Listener Rules:**
- Priority 100: `/api*` → Backend Target Group
- Default: All others → Frontend Target Group

---

## 📝 Workflow

### Before (Manual):
1. `terraform apply` (15-20 min)
2. Get Load Balancer URL manually
3. Create Frontend Target Group manually
4. Create Backend Target Group manually
5. Register worker nodes manually
6. Configure ALB listener rules manually
7. Update security groups manually
8. Update ConfigMap manually
9. Copy k8s files manually
10. Apply k8s manifests manually
11. Restart pods manually

**Total Time:** 45-60 minutes

---

### After (Automated):
1. `terraform apply` (15-20 min)
2. `./post-apply.sh` (2-3 min)

**Total Time:** 17-23 minutes

**Manual Steps:** 0 ✅

---

## 🧪 Testing

### After Deployment:

```bash
# Get Load Balancer URL
terraform output load_balancer_dns

# Test Frontend
curl http://$(terraform output -raw load_balancer_dns)/

# Test Backend API
curl http://$(terraform output -raw load_balancer_dns)/api/products
```

---

## 🔄 LAB Practice Workflow

### Every 4-Hour LAB Session:

```bash
# 1. Navigate to Terraform directory
cd terraform/simple-k8s

# 2. Deploy everything (one command)
terraform apply && ./post-apply.sh

# 3. Wait 2-3 minutes

# 4. Get URL and test
terraform output load_balancer_dns
# Open in browser: http://<LB_DNS>
```

**No manual configuration needed!** ✅

---

## 🐛 Troubleshooting

### Issue: Terraform Apply Fails

**Check:**
- AWS credentials configured?
- Region correct (ap-southeast-1)?
- VPC/subnet limits not exceeded?

### Issue: post-apply.sh Fails

**Check:**
- Terraform outputs available?
- SSH key exists?
- Master-1 accessible?
- k8s/ folder exists in project root?

### Issue: ConfigMap Not Updated

**Check:**
- Load Balancer DNS in outputs?
- Script has correct paths?
- Master-1 has kubectl access?

---

## 📊 Summary

### What's Automated:

- ✅ Target Groups (Frontend + Backend)
- ✅ Target Group Attachments (Worker nodes)
- ✅ ALB Listener Rules (Path-based routing)
- ✅ Security Groups (NodePort access)
- ✅ ConfigMap Update (Load Balancer URL)
- ✅ k8s Files Copy (to Master-1)
- ✅ k8s Manifests Apply
- ✅ Pod Restart

### What You Need to Do:

1. Run: `terraform apply && ./post-apply.sh`
2. Wait 2-3 minutes
3. Test website

**That's it!** 🎉

---

**Created:** 2025-12-01 
**Status:** Ready to Use ✅

