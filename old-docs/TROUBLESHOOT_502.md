# 🔧 502 Bad Gateway Troubleshooting Guide

**Issue**: 502 Bad Gateway even though pods are running  
**Date**: 2024-11-30

---

## ✅ Current Status

- ✅ All pods are Running and Ready
- ❌ Load Balancer returns 502 Bad Gateway
- ❌ Frontend service might not be accessible from Load Balancer

---

## Step-by-Step Troubleshooting

### Step 1: Verify Frontend Service Type and NodePort

**Master-1 এ:**

```bash
kubectl get svc -n dhakacart dhakacart-frontend-service
```

**Expected Output:**
```
NAME                        TYPE       PORT(S)
dhakacart-frontend-service  NodePort   80:30080/TCP
```

**If shows ClusterIP instead of NodePort:**
```bash
kubectl patch svc dhakacart-frontend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'
```

---

### Step 2: Get NodePort Number

```bash
kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}'
echo ""
```

**Expected:** `30080` (or similar number like 30000-32767)

**Note this number** - you'll need it for AWS configuration.

---

### Step 3: Test NodePort Directly on Worker Nodes

**Master-1 এ:**

```bash
# Test on each worker node
curl -v http://10.0.10.170:30080  # Worker-1
curl -v http://10.0.10.12:30080   # Worker-2
curl -v http://10.0.10.84:30080   # Worker-3
```

**Expected:** HTML response (frontend page)

**If this fails:**
- Pods might not be responding
- Check pods: `kubectl get pods -n dhakacart -l app=dhakacart-frontend`
- Check logs: `kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=50`

---

### Step 4: Check AWS Load Balancer Target Group

**AWS Console → EC2 → Target Groups:**

1. **Find target group for dhakacart-k8s-alb**

2. **Check "Targets" tab:**
   - Are worker nodes registered?
   - What port is configured? (Should be 30080 or your NodePort)
   - Health status: Healthy or Unhealthy?

3. **If targets are Unhealthy:**
   - Check health check configuration
   - Port: Should match NodePort (30080)
   - Path: `/` or `/health`
   - Protocol: HTTP

4. **If targets are missing:**
   - Click "Register targets"
   - Add worker nodes:
     - 10.0.10.170:30080
     - 10.0.10.12:30080
     - 10.0.10.84:30080
   - Click "Register targets"
   - Wait 1-2 minutes for health checks

---

### Step 5: Verify Security Groups

**AWS Console → EC2 → Security Groups:**

1. **Find worker nodes security group:**
   - Name: `dhakacart-k8s-worker-sg` or similar

2. **Check Inbound Rules:**
   - Is there a rule allowing TCP port 30080 (or your NodePort)?
   - Source: Load Balancer security group OR 0.0.0.0/0 (for testing)

3. **If rule is missing:**
   - Click "Edit inbound rules"
   - Add rule:
     - Type: Custom TCP
     - Port: 30080 (or your NodePort)
     - Source: Load Balancer SG or 0.0.0.0/0
     - Description: "Allow NodePort from Load Balancer"
   - Save rules

4. **Check Load Balancer security group:**
   - Should allow inbound HTTP (port 80) from 0.0.0.0/0
   - Should allow outbound to worker nodes

---

### Step 6: Verify Load Balancer Listener

**AWS Console → EC2 → Load Balancers:**

1. **Select dhakacart-k8s-alb**

2. **Check "Listeners" tab:**
   - Is there a listener on port 80?
   - Default action: Forward to target group
   - Target group: Should point to frontend target group

3. **If listener is missing:**
   - Click "Add listener"
   - Protocol: HTTP
   - Port: 80
   - Default action: Forward to target group
   - Select the frontend target group
   - Save

---

### Step 7: Check Target Group Health Check Configuration

**AWS Console → Target Groups → Health checks:**

1. **Protocol:** HTTP
2. **Path:** `/` or `/health`
3. **Port:** 30080 (or your NodePort) - **IMPORTANT!**
4. **Healthy threshold:** 2
5. **Unhealthy threshold:** 2
6. **Timeout:** 5 seconds
7. **Interval:** 30 seconds

**Common Issue:** Health check port is wrong!
- Should be: NodePort (30080)
- Not: Service port (80) or Container port (3000)

---

## Quick Fix Commands (Master-1)

```bash
# 1. Check service
kubectl get svc -n dhakacart dhakacart-frontend-service

# 2. Get NodePort
NODEPORT=$(kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODEPORT"

# 3. Test NodePort directly
echo "Testing Worker-1..."
curl -v http://10.0.10.170:$NODEPORT 2>&1 | head -20

# 4. Check pods
kubectl get pods -n dhakacart -l app=dhakacart-frontend

# 5. Check service endpoints
kubectl get endpoints -n dhakacart dhakacart-frontend-service

# 6. Check frontend pod logs
kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=50
```

---

## Common Issues & Solutions

### Issue 1: Service Type is ClusterIP

**Symptom:** Service shows `ClusterIP` instead of `NodePort`

**Solution:**
```bash
kubectl patch svc dhakacart-frontend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'
```

---

### Issue 2: Target Group Port Mismatch

**Symptom:** Targets show Unhealthy, health checks failing

**Solution:**
- AWS Console → Target Groups → Health checks
- Change port to NodePort (30080)
- Update target registrations to use NodePort

---

### Issue 3: Security Group Blocking

**Symptom:** Direct NodePort test works, but Load Balancer doesn't

**Solution:**
- Add inbound rule: Allow TCP port 30080 from Load Balancer SG

---

### Issue 4: Target Group Has Wrong Targets

**Symptom:** Targets are master nodes instead of worker nodes

**Solution:**
- Deregister master nodes
- Register worker nodes with correct port (30080)

---

## Verification Checklist

- [ ] Frontend service is NodePort type
- [ ] NodePort number obtained (e.g., 30080)
- [ ] NodePort test works directly on worker nodes
- [ ] Target group has worker nodes registered
- [ ] Target group port matches NodePort (30080)
- [ ] Health checks are passing (targets show Healthy)
- [ ] Security group allows port 30080 from Load Balancer
- [ ] Load Balancer listener is configured (Port 80)
- [ ] Load Balancer forwards to correct target group

---

## Expected Final Status

After fixing:
- ✅ Target group shows all targets as Healthy
- ✅ Health checks pass on port 30080
- ✅ Website loads in browser (no 502 error)
- ✅ Load Balancer forwards requests correctly

---

## Debug Commands

**Master-1 এ:**

```bash
# Complete status check
echo "=== Service Status ==="
kubectl get svc -n dhakacart dhakacart-frontend-service

echo ""
echo "=== NodePort Number ==="
kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}'
echo ""

echo "=== Pods Status ==="
kubectl get pods -n dhakacart -l app=dhakacart-frontend

echo ""
echo "=== Service Endpoints ==="
kubectl get endpoints -n dhakacart dhakacart-frontend-service

echo ""
echo "=== Testing NodePort ==="
NODEPORT=$(kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "Testing on Worker-1 (10.0.10.170:$NODEPORT)..."
curl -I http://10.0.10.170:$NODEPORT 2>&1 | head -5
```

---

**Last Updated**: 2024-11-30  
**Status**: Troubleshooting Guide ✅

