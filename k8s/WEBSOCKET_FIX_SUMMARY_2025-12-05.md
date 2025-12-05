# WebSocket Connection Fix - Complete Summary

**তারিখ:** ৫ ডিসেম্বর, ২০২৫  
**সমস্যা:** Frontend WebSocket connections failing with port 3000 timeout  
**সমাধান:** Production build (Nginx port 80) use করা এবং dynamic ALB DNS support

---

## 🔍 Root Causes Identified

1. **Wrong Port:** Frontend deployment port 3000 use করছিল (React dev server)
2. **Production Build Missing:** Nginx (port 80) use করা হয়নি
3. **Hardcoded DNS:** ConfigMap এ hardcoded ALB DNS ছিল
4. **WebSocket Support:** ALB এবং Nginx এ WebSocket support ছিল না

---

## ✅ Changes Made

### 1. Frontend Deployment (`k8s/deployments/frontend-deployment.yaml`)

**Before:**
```yaml
ports:
- containerPort: 3000  # React dev server
livenessProbe:
  port: 3000
```

**After:**
```yaml
ports:
- containerPort: 80  # Nginx production
livenessProbe:
  port: 80
```

### 2. Frontend Service (`k8s/services/services.yaml`)

**Before:**
```yaml
targetPort: 3000  # Wrong port
```

**After:**
```yaml
targetPort: 80  # Nginx port
```

### 3. Nginx Configuration (`frontend/nginx.conf`)

**Added:**
- WebSocket support (`/ws` location)
- Kubernetes service DNS ব্যবহার
- Proper proxy headers for WebSocket

### 4. ALB Configuration (`terraform/simple-k8s/alb-backend-config.tf`)

**Added:**
- WebSocket support (stickiness disabled)
- `/ws` path routing to backend
- Connection draining

### 5. Dynamic ConfigMap Update Script

**Created:**
- `k8s/update-configmap-with-alb-dns.sh` - Automatic ALB DNS update
- Terraform output থেকে DNS extract করে
- ConfigMap update করে এবং pods restart করে

---

## 🚀 Deployment Steps

### Step 1: Update Kubernetes Resources

```bash
# Apply updated deployments and services
kubectl apply -f k8s/deployments/frontend-deployment.yaml
kubectl apply -f k8s/services/services.yaml
```

### Step 2: Rebuild Frontend Image (if needed)

**Important:** Docker image production stage use করতে হবে:

```bash
cd frontend

# Build with production stage
docker build --target production -t arifhossaincse22/dhakacart-frontend:v1.0.2 .

# Push to registry
docker push arifhossaincse22/dhakacart-frontend:v1.0.2
```

**Or update deployment to use production:**
```yaml
# In frontend-deployment.yaml, ensure image uses production build
image: arifhossaincse22/dhakacart-frontend:v1.0.2  # Update version
```

### Step 3: Update ConfigMap with ALB DNS

```bash
cd k8s

# Automatic (recommended)
./update-configmap-with-alb-dns.sh

# Or manual
./update-configmap-with-alb-dns.sh <ALB_DNS>
```

### Step 4: Apply Terraform Changes

```bash
cd terraform/simple-k8s
terraform apply
```

---

## 🔄 After ALB DNS Changes (Every 4 hours in LAB)

```bash
# Simply run the update script
cd k8s
./update-configmap-with-alb-dns.sh
```

Script automatically:
1. Terraform থেকে নতুন DNS extract করবে
2. ConfigMap update করবে
3. Frontend pods restart করবে

---

## ✅ Verification

### Check Frontend Pods:

```bash
kubectl get pods -n dhakacart -l app=dhakacart-frontend
kubectl describe pod <pod-name> -n dhakacart | grep Image
# Should show: arifhossaincse22/dhakacart-frontend:v1.0.2 (or latest)
```

### Check Container Port:

```bash
kubectl get pod <pod-name> -n dhakacart -o jsonpath='{.spec.containers[0].ports[0].containerPort}'
# Should output: 80
```

### Check ConfigMap:

```bash
kubectl get configmap dhakacart-config -n dhakacart -o yaml | grep REACT_APP_API_URL
# Should show current ALB DNS
```

### Test WebSocket:

```bash
# Using wscat (install: npm install -g wscat)
wscat -c ws://<ALB_DNS>/ws

# Should connect successfully (no timeout)
```

---

## 📋 File Changes Summary

| File | Change | Purpose |
|------|--------|---------|
| `k8s/deployments/frontend-deployment.yaml` | Port 3000 → 80 | Use Nginx production |
| `k8s/services/services.yaml` | targetPort 3000 → 80 | Match container port |
| `frontend/nginx.conf` | Added `/ws` location | WebSocket support |
| `terraform/simple-k8s/alb-backend-config.tf` | WebSocket config | ALB WebSocket support |
| `k8s/update-configmap-with-alb-dns.sh` | New script | Dynamic DNS update |
| `k8s/README_CONFIGMAP_UPDATE_2025-12-05.md` | New doc | Usage guide |

---

## 🎯 Expected Results

After applying all changes:

1. ✅ Frontend runs on port 80 (Nginx, not React dev server)
2. ✅ No WebSocket connection errors
3. ✅ Dynamic ALB DNS support
4. ✅ Automatic ConfigMap updates
5. ✅ WebSocket connections work through ALB

---

## 🐛 Troubleshooting

### Issue: Still seeing port 3000 errors

**Solution:**
```bash
# Check if frontend image is production build
kubectl describe pod -n dhakacart -l app=dhakacart-frontend | grep Image

# If not production, rebuild image:
cd frontend
docker build --target production -t arifhossaincse22/dhakacart-frontend:v1.0.2 .
docker push arifhossaincse22/dhakacart-frontend:v1.0.2

# Update deployment
kubectl set image deployment/dhakacart-frontend frontend=arifhossaincse22/dhakacart-frontend:v1.0.2 -n dhakacart
```

### Issue: ConfigMap not updating

**Solution:**
```bash
# Check script permissions
chmod +x k8s/update-configmap-with-alb-dns.sh

# Run manually with DNS
./k8s/update-configmap-with-alb-dns.sh <ALB_DNS>
```

### Issue: WebSocket still timing out

**Solution:**
```bash
# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn <arn> --region ap-southeast-1

# Check security groups allow port 30080
# Check backend service is running
kubectl get svc -n dhakacart dhakacart-backend-service
```

---

## 📚 Related Documentation

- `k8s/WEBSOCKET_TROUBLESHOOTING_2025-12-05.md` - Detailed troubleshooting
- `k8s/README_CONFIGMAP_UPDATE_2025-12-05.md` - ConfigMap update guide
- `terraform/simple-k8s/alb-backend-config.tf` - ALB configuration

---

**Status:** All fixes applied ✅  
**Next Step:** Rebuild frontend image with production stage and deploy

