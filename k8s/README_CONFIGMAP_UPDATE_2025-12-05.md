# ConfigMap Dynamic Update Guide

**তারিখ:** ৫ ডিসেম্বর, ২০২৫  
**লক্ষ্য:** ALB DNS dynamically change হলে ConfigMap automatically update করা

---

## 🔍 Problem

AWS LAB environment এ ALB DNS প্রতি 4 ঘন্টা পর change হয়। Frontend ConfigMap এ hardcoded ALB DNS থাকলে প্রতিবার manually update করতে হয়।

---

## ✅ Solution

Automation script তৈরি করা হয়েছে যা:
1. Terraform output থেকে ALB DNS automatically extract করে
2. ConfigMap update করে
3. Frontend pods restart করে

---

## 🚀 Usage

### Method 1: Automatic (Recommended)

Script automatically Terraform থেকে ALB DNS extract করবে:

```bash
cd k8s
./update-configmap-with-alb-dns.sh
```

### Method 2: Manual DNS Provide

যদি Terraform output না পাওয়া যায়, manually DNS provide করুন:

```bash
cd k8s
./update-configmap-with-alb-dns.sh dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com
```

---

## 📋 What the Script Does

1. **Extract ALB DNS:**
   - Terraform output থেকে `load_balancer_dns` extract করে
   - বা manually provided DNS use করে

2. **Update ConfigMap:**
   - `configmaps/app-config.yaml` file update করে
   - Backup তৈরি করে (`.backup.TIMESTAMP`)

3. **Apply to Kubernetes:**
   - `kubectl apply` দিয়ে ConfigMap apply করে

4. **Restart Frontend:**
   - Frontend deployment restart করে
   - নতুন config pick up করার জন্য

---

## 🔄 Workflow

### After Terraform Apply:

```bash
# 1. Terraform apply করুন
cd terraform/simple-k8s
terraform apply

# 2. ConfigMap update করুন
cd ../../k8s
./update-configmap-with-alb-dns.sh

# 3. Verify
kubectl get configmap dhakacart-config -n dhakacart -o yaml | grep REACT_APP_API_URL
```

### When ALB DNS Changes:

```bash
# Same process - script automatically detects new DNS
cd k8s
./update-configmap-with-alb-dns.sh
```

---

## 📝 Manual Update (If Script Fails)

```bash
# 1. Get ALB DNS from Terraform
cd terraform/simple-k8s
terraform output load_balancer_dns

# 2. Update ConfigMap manually
cd ../../k8s
kubectl patch configmap dhakacart-config -n dhakacart --type merge -p '{
  "data": {
    "REACT_APP_API_URL": "http://YOUR_ALB_DNS/api"
  }
}'

# 3. Restart frontend
kubectl rollout restart deployment/dhakacart-frontend -n dhakacart
```

---

## ✅ Verification

```bash
# Check ConfigMap
kubectl get configmap dhakacart-config -n dhakacart -o yaml

# Check frontend pods
kubectl get pods -n dhakacart -l app=dhakacart-frontend

# Check frontend logs
kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=20
```

---

## 🎯 Benefits

- ✅ **Automatic:** No manual DNS entry needed
- ✅ **Dynamic:** Works with changing ALB DNS
- ✅ **Safe:** Creates backup before update
- ✅ **Complete:** Updates ConfigMap and restarts pods

---

## 📚 Related Files

- `configmaps/app-config.yaml` - ConfigMap definition
- `configmaps/app-config.yaml.template` - Template (if needed)
- `update-configmap-with-alb-dns.sh` - Automation script

---

**Status:** Ready to Use 🚀

