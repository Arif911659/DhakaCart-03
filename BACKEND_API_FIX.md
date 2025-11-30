# 🔧 Backend API Connection Fix

**Issue**: Frontend cannot connect to backend API  
**Error**: `GET http://172.19.218.171:5000/api/products net::ERR_CONNECTION_TIMED_OUT`  
**Date**: 2024-11-30

---

## Problem Analysis

### Current Issue
- Frontend ConfigMap has hardcoded IP: `http://172.19.218.171:5000/api`
- This IP is not accessible in Kubernetes cluster
- Backend service is `ClusterIP` (internal only)
- Browser cannot access ClusterIP services

### Solution
1. Expose backend service as NodePort (30081)
2. Update ConfigMap to use Load Balancer URL with backend path
3. Configure Load Balancer listener rules for path-based routing

---

## Step-by-Step Fix

### Step 1: Apply Updated ConfigMap

**Master-1 এ এই command run করুন:**

```bash
# ConfigMap apply করুন
kubectl apply -f ~/k8s/configmaps/app-config.yaml

# Restart frontend pods to pick up new config
kubectl rollout restart deployment dhakacart-frontend -n dhakacart
```

---

### Step 2: Apply Updated Backend Service

**Master-1 এ:**

```bash
# Backend service apply করুন
kubectl apply -f ~/k8s/services/services.yaml

# Verify NodePort
kubectl get svc -n dhakacart dhakacart-backend-service
```

**Expected Output:**
```
NAME                      TYPE       PORT(S)
dhakacart-backend-service NodePort   5000:30081/TCP
```

---

### Step 3: Configure AWS Load Balancer for Backend API

#### Option A: Path-Based Routing (Recommended)

**AWS Console → EC2 → Load Balancers:**

1. **dhakacart-k8s-alb select করুন**

2. **"Listeners" tab → Listener (Port 80) → View/edit rules**

3. **Default action: Forward to frontend target group**

4. **Add rule:**
   ```
   IF (path is /api/*)
   THEN (forward to backend target group)
   ```

5. **Create Backend Target Group:**
   - Name: `dhakacart-k8s-backend-tg`
   - Protocol: HTTP
   - Port: `30081`
   - Health check: HTTP on port 30081, path: `/health` or `/api/health`

6. **Register Worker Nodes:**
   - worker-1: `10.0.10.170:30081`
   - worker-2: `10.0.10.12:30081`
   - worker-3: `10.0.10.84:30081`

#### Option B: Separate Backend Load Balancer (Alternative)

If path-based routing is not available:
1. Create separate target group for backend (port 30081)
2. Register worker nodes
3. Update ConfigMap to use a different URL (if using separate ALB)

---

### Step 4: Update Security Group

**AWS Console → EC2 → Security Groups:**

1. **Worker nodes security group → Inbound Rules**

2. **Add rule:**
   - Type: Custom TCP
   - Port: `30081`
   - Source: Load Balancer security group
   - Description: "Allow backend NodePort from Load Balancer"

---

### Step 5: Verify Backend API

**Master-1 এ test করুন:**

```bash
# Test backend NodePort directly
curl http://10.0.10.170:30081/api/products  # Worker-1
curl http://10.0.10.12:30081/api/products   # Worker-2
curl http://10.0.10.84:30081/api/products   # Worker-3
```

**Expected:** JSON response with products

---

### Step 6: Test Frontend API Connection

**Browser Console এ:**

After frontend pods restart, check:
- Network tab should show requests to: `http://dhakacart-k8s-alb-1098869932.ap-southeast-1.elb.amazonaws.com/api/products`
- Should get 200 OK response

---

## ConfigMap Update

### Updated API URL

```yaml
REACT_APP_API_URL: "http://dhakacart-k8s-alb-1098869932.ap-southeast-1.elb.amazonaws.com/api"
```

**Why this works:**
- Browser can access Load Balancer URL
- Load Balancer routes `/api/*` to backend service
- Backend service forwards to backend pods

---

## Port Configuration Summary

### Backend Service

```yaml
type: NodePort
ports:
- port: 5000          # Service port
  targetPort: 5000    # Container port
  nodePort: 30081     # Fixed NodePort
```

### Frontend Service

```yaml
type: NodePort
ports:
- port: 80            # Service port
  targetPort: 3000    # Container port
  nodePort: 30080     # Fixed NodePort
```

---

## Quick Fix Commands

**Master-1 এ:**

```bash
# 1. Apply ConfigMap
kubectl apply -f ~/k8s/configmaps/app-config.yaml

# 2. Apply Backend Service
kubectl apply -f ~/k8s/services/services.yaml

# 3. Restart Frontend
kubectl rollout restart deployment dhakacart-frontend -n dhakacart

# 4. Verify
kubectl get svc -n dhakacart
kubectl get pods -n dhakacart

# 5. Check backend NodePort
kubectl get svc -n dhakacart dhakacart-backend-service
```

---

## Load Balancer Configuration

### Listener Rules (Path-Based Routing)

```
Default Action:
└── Forward to: dhakacart-k8s-frontend-tg (Port 30080)

Rule 1: /api/*
└── Forward to: dhakacart-k8s-backend-tg (Port 30081)
```

### Target Groups

**Frontend Target Group:**
- Port: 30080
- Targets: Worker nodes on port 30080

**Backend Target Group:**
- Port: 30081
- Targets: Worker nodes on port 30081

---

## Troubleshooting

### Issue 1: Backend API Still Not Working

**Check:**
```bash
# Test backend directly
curl http://10.0.10.170:30081/api/products

# Check backend pods
kubectl get pods -n dhakacart -l app=dhakacart-backend

# Check backend logs
kubectl logs -n dhakacart -l app=dhakacart-backend --tail=50
```

### Issue 2: Frontend Still Shows Old API URL

**Solution:**
```bash
# Restart frontend pods
kubectl rollout restart deployment dhakacart-frontend -n dhakacart

# Check ConfigMap
kubectl get configmap dhakacart-config -n dhakacart -o yaml
```

### Issue 3: Load Balancer Path Routing Not Working

**Alternative:** Use separate target group and configure listener to forward all `/api/*` to backend target group.

---

## Expected Result

After fixing:
- ✅ Frontend can fetch products from `/api/products`
- ✅ Frontend can fetch categories from `/api/categories`
- ✅ No more connection timeout errors
- ✅ API calls go through Load Balancer to backend

---

**Last Updated**: 2024-11-30  
**Status**: Ready to Fix ✅

