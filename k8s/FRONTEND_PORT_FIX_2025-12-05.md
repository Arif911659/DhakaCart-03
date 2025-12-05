# Frontend Port 30080 Connection Issue - Fix Guide

**তারিখ:** ৫ ডিসেম্বর, ২০২৫  
**সমস্যা:** NodePort 30080 connection refused, ALB 502 Bad Gateway  
**কারণ:** Frontend Docker image production build (Nginx) use করছে না

---

## 🔍 Problem Diagnosis

### Symptoms:
- ❌ `curl http://<node-ip>:30080` → Connection refused
- ❌ Service connection refused
- ❌ ALB → 502 Bad Gateway
- ✅ Pods are Running and Ready

### Root Cause:
Docker image `arifhossaincse22/dhakacart-frontend:v1.0.2` production stage (`--target production`) দিয়ে build হয়নি, তাই:
- React dev server (port 3000) চালাচ্ছে
- Nginx (port 80) চালাচ্ছে না
- Service port 80-এ connect করতে পারছে না

---

## ✅ Solution Steps

### Step 1: Verify Current Image

```bash
# Check what's running in pod
kubectl exec -n dhakacart <pod-name> -- ps aux

# If you see "node" or "npm", it's dev server (WRONG)
# If you see "nginx", it's production (CORRECT)
```

### Step 2: Rebuild Frontend Image with Production Stage

```bash
cd frontend

# Build with production target
docker build --target production -t arifhossaincse22/dhakacart-frontend:v1.0.3 .

# Verify image
docker run --rm -d -p 8080:80 --name test-frontend arifhossaincse22/dhakacart-frontend:v1.0.3
curl http://localhost:8080
docker stop test-frontend

# Push to registry
docker push arifhossaincse22/dhakacart-frontend:v1.0.3
```

### Step 3: Update Deployment

```bash
# Update image in deployment
kubectl set image deployment/dhakacart-frontend \
  frontend=arifhossaincse22/dhakacart-frontend:v1.0.3 \
  -n dhakacart

# Or update deployment file
# Edit: k8s/deployments/frontend-deployment.yaml
# Change: image: arifhossaincse22/dhakacart-frontend:v1.0.3
# Then: kubectl apply -f k8s/deployments/frontend-deployment.yaml -n dhakacart
```

### Step 4: Verify Fix

```bash
# Wait for rollout
kubectl rollout status deployment/dhakacart-frontend -n dhakacart

# Check pod processes (should show nginx)
kubectl exec -n dhakacart <new-pod-name> -- ps aux

# Check listening ports (should show port 80)
kubectl exec -n dhakacart <new-pod-name> -- netstat -tlnp

# Test from pod
kubectl exec -n dhakacart <new-pod-name> -- curl -I http://localhost:80

# Test NodePort
curl http://<worker-node-ip>:30080
```

---

## 🔧 Alternative: Quick Test with Port Forward

If you can't rebuild image immediately:

```bash
# Port forward to test service
kubectl port-forward -n dhakacart svc/dhakacart-frontend-service 8080:80

# Test
curl http://localhost:8080
```

If this works, the issue is definitely the image not being production build.

---

## 📋 Verification Checklist

After fix:

- [ ] Pod shows `nginx` process (not `node`)
- [ ] Container listening on port 80 (not 3000)
- [ ] `curl http://localhost:80` from pod works
- [ ] Service endpoints show pod IPs
- [ ] NodePort 30080 accessible from nodes
- [ ] ALB target group shows healthy
- [ ] ALB URL works (no 502)

---

## 🐛 Troubleshooting

### Issue: Image still not working after rebuild

**Check:**
```bash
# Verify image was built correctly
docker run --rm arifhossaincse22/dhakacart-frontend:v1.0.3 ps aux
# Should show: nginx master process

docker run --rm -p 8080:80 arifhossaincse22/dhakacart-frontend:v1.0.3
# In another terminal:
curl http://localhost:8080
# Should return HTML
```

### Issue: Service endpoints empty

**Fix:**
```bash
# Check service selector matches pod labels
kubectl get svc -n dhakacart dhakacart-frontend-service -o yaml | grep selector
kubectl get pods -n dhakacart -l app=dhakacart-frontend --show-labels

# Should match: app=dhakacart-frontend
```

### Issue: ALB still 502

**Check:**
```bash
# Verify target group health
# AWS Console → EC2 → Target Groups → Check health

# Verify security groups allow port 30080
# Verify worker nodes are registered in target group
```

---

## 📚 Related Files

- `frontend/Dockerfile` - Multi-stage build with production stage
- `frontend/nginx.conf` - Nginx configuration
- `k8s/deployments/frontend-deployment.yaml` - Deployment config
- `k8s/services/services.yaml` - Service config

---

## 🚀 Quick Fix Command Summary

```bash
# 1. Rebuild image
cd frontend
docker build --target production -t arifhossaincse22/dhakacart-frontend:v1.0.3 .
docker push arifhossaincse22/dhakacart-frontend:v1.0.3

# 2. Update deployment
kubectl set image deployment/dhakacart-frontend frontend=arifhossaincse22/dhakacart-frontend:v1.0.3 -n dhakacart

# 3. Wait and verify
kubectl rollout status deployment/dhakacart-frontend -n dhakacart
kubectl exec -n dhakacart $(kubectl get pod -n dhakacart -l app=dhakacart-frontend -o jsonpath='{.items[0].metadata.name}') -- curl -I http://localhost:80
```

---

**Status:** Active Issue  
**Priority:** Critical  
**Last Updated:** ৫ ডিসেম্বর, ২০২৫

