# Frontend Port 30080 Connection Issue - Troubleshooting

**তারিখ:** ৫ ডিসেম্বর, ২০২৫  
**সমস্যা:** NodePort 30080 connection refused, ALB 502 Bad Gateway

---

## 🔍 Problem Analysis

### Symptoms:
1. `curl http://<node-ip>:30080` → Connection refused
2. `curl http://dhakacart-frontend-service.dhakacart.svc.cluster.local` → Connection refused
3. ALB → 502 Bad Gateway
4. Frontend pods are Running and Ready

### Root Cause:
Frontend Docker image `arifhossaincse22/dhakacart-frontend:v1.0.2` might be:
- Still using React dev server (port 3000) instead of Nginx (port 80)
- Or Nginx is not properly configured/started

---

## ✅ Solutions

### Solution 1: Verify Docker Image Build

**Check if image is production build:**

```bash
# On Master-1
kubectl exec -n dhakacart <frontend-pod-name> -- ps aux
# Should show: nginx (not node/npm)

kubectl exec -n dhakacart <frontend-pod-name> -- netstat -tlnp
# Should show: port 80 listening (not 3000)
```

**If image is NOT production build:**

```bash
# Rebuild with production stage
cd frontend
docker build --target production -t arifhossaincse22/dhakacart-frontend:v1.0.3 .
docker push arifhossaincse22/dhakacart-frontend:v1.0.3

# Update deployment
kubectl set image deployment/dhakacart-frontend frontend=arifhossaincse22/dhakacart-frontend:v1.0.3 -n dhakacart
```

### Solution 2: Check Service Endpoints

```bash
# Check if service has endpoints
kubectl get endpoints -n dhakacart dhakacart-frontend-service

# Should show pod IPs and port 80
# If empty, service selector might not match pod labels
```

### Solution 3: Verify Service Configuration

```bash
# Check service
kubectl get svc -n dhakacart dhakacart-frontend-service -o yaml

# Verify:
# - type: NodePort
# - port: 80
# - targetPort: 80
# - nodePort: 30080
# - selector matches pod labels
```

### Solution 4: Test Pod Directly

```bash
# Test from inside pod
kubectl exec -n dhakacart <frontend-pod-name> -- curl http://localhost:80

# Test from another pod
kubectl run test-pod --rm -i --tty --image=curlimages/curl --restart=Never -- curl http://dhakacart-frontend-service.dhakacart.svc.cluster.local
```

### Solution 5: Check ALB Target Group

```bash
# Verify ALB target group health
# AWS Console → EC2 → Target Groups → Check health status

# Or via AWS CLI
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-southeast-1
```

---

## 🔧 Quick Diagnostic Commands

```bash
# 1. Check pod status
kubectl get pods -n dhakacart -l app=dhakacart-frontend -o wide

# 2. Check pod logs
kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=50

# 3. Check service
kubectl get svc -n dhakacart dhakacart-frontend-service

# 4. Check endpoints
kubectl get endpoints -n dhakacart dhakacart-frontend-service

# 5. Check what's running in container
kubectl exec -n dhakacart <pod-name> -- ps aux

# 6. Check listening ports
kubectl exec -n dhakacart <pod-name> -- netstat -tlnp || \
kubectl exec -n dhacart <pod-name> -- ss -tlnp

# 7. Test from pod
kubectl exec -n dhakacart <pod-name> -- curl -I http://localhost:80
```

---

## 🎯 Most Likely Issue

**Frontend image is NOT production build!**

The image `arifhossaincse22/dhakacart-frontend:v1.0.2` might be:
- Built without `--target production`
- Still using React dev server on port 3000
- Nginx not included or not started

**Fix:**
1. Rebuild image with production stage
2. Update deployment with new image
3. Verify pod is running Nginx on port 80

---

## 📋 Verification Checklist

- [ ] Frontend pod is Running and Ready
- [ ] Container is listening on port 80 (not 3000)
- [ ] Nginx is running (not React dev server)
- [ ] Service has endpoints (pod IPs listed)
- [ ] Service targetPort matches container port (80)
- [ ] NodePort 30080 is accessible
- [ ] ALB target group shows healthy targets

---

**Status:** Active Issue  
**Priority:** High  
**Last Updated:** ৫ ডিসেম্বর, ২০২৫

