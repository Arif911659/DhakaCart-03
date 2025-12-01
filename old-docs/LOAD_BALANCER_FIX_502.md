# 🔧 502 Bad Gateway Fix - Load Balancer Configuration

**Issue**: 502 Bad Gateway when accessing Load Balancer  
**Root Cause**: Frontend service is `ClusterIP` instead of `NodePort`  
**Date**: 2024-11-30

---

## Problem Analysis

### Current Issue
- Frontend service is `type: ClusterIP` (internal only)
- Load Balancer cannot access ClusterIP services
- Load Balancer needs to target worker nodes on a NodePort

### Solution
1. Change frontend service to `NodePort` type
2. Get the NodePort number (e.g., 30080)
3. Configure Load Balancer target group to point to worker nodes on that NodePort
4. Update security groups to allow traffic

---

## Step-by-Step Fix

### Step 1: Update Frontend Service to NodePort

**Master-1 এ এই command run করুন:**

```bash
# Service type change করুন
kubectl patch svc dhakacart-frontend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'

# Verify
kubectl get svc -n dhakacart dhakacart-frontend-service
```

**Expected Output:**
```
NAME                        TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
dhakacart-frontend-service  NodePort   10.97.95.115    <none>        80:30080/TCP
```

**Note the NodePort number** (e.g., `30080`)

---

### Step 2: Get NodePort Number

```bash
# Get NodePort number
kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}'
```

**Save this number** (e.g., `30080`)

---

### Step 3: Configure AWS Load Balancer Target Group

**AWS Console এ:**

1. **EC2 → Target Groups**
   - URL: https://console.aws.amazon.com/ec2/v2/home?region=ap-southeast-1#TargetGroups:

2. **dhakacart-k8s-alb এর target group select করুন**

3. **"Targets" tab → "Register targets"**

4. **Worker nodes add করুন:**
   - ✅ worker-1: `10.0.10.170` Port: `30080` (or your NodePort number)
   - ✅ worker-2: `10.0.10.12` Port: `30080`
   - ✅ worker-3: `10.0.10.84` Port: `30080`

5. **"Register targets" click করুন**

6. **Health checks wait করুন** (১-২ মিনিট)
   - Status "healthy" হতে হবে

---

### Step 4: Verify Security Groups

**AWS Console → EC2 → Security Groups:**

1. **Worker nodes এর security group select করুন**
   - Name: `dhakacart-k8s-worker-sg` বা similar

2. **Inbound Rules → Edit**

3. **Add rule (যদি না থাকে):**
   - Type: Custom TCP
   - Port: `30080` (or your NodePort number)
   - Source: Load Balancer security group (বা 0.0.0.0/0 for testing)
   - Description: "Allow NodePort from Load Balancer"

4. **Save rules**

---

### Step 5: Verify Load Balancer Listener

**AWS Console → EC2 → Load Balancers:**

1. **dhakacart-k8s-alb select করুন**

2. **"Listeners" tab**

3. **Listener check করুন:**
   - Port: 80
   - Protocol: HTTP
   - Default action: Forward to target group (dhakacart-k8s-alb-tg)

4. **যদি listener না থাকে, "Add listener" click করুন:**
   - Protocol: HTTP
   - Port: 80
   - Default action: Forward to target group
   - Target group: dhakacart-k8s-alb-tg

---

### Step 6: Test Website

**Browser এ:**
```
http://dhakacart-k8s-alb-1098869932.ap-southeast-1.elb.amazonaws.com
```

**⏱️ Wait:** ২-৩ মিনিট (Load Balancer propagate হতে সময় লাগে)

---

## Quick Fix Commands (Master-1 এ)

```bash
# 1. Service to NodePort
kubectl patch svc dhakacart-frontend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'

# 2. Get NodePort number
NODEPORT=$(kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODEPORT"

# 3. Verify service
kubectl get svc -n dhakacart dhakacart-frontend-service

# 4. Check pods are running
kubectl get pods -n dhakacart -l app=dhakacart-frontend
```

**Output Example:**
```
NodePort: 30080
NAME                        TYPE       PORT(S)
dhakacart-frontend-service  NodePort   80:30080/TCP
```

---

## Troubleshooting

### Issue 1: Target Group Unhealthy

**Check:**
```bash
# From Master-1, test NodePort directly
curl http://10.0.10.170:30080  # Worker-1
curl http://10.0.10.12:30080   # Worker-2
curl http://10.0.10.84:30080   # Worker-3
```

**If curl works:** Security group issue  
**If curl fails:** Pods/service issue

---

### Issue 2: Service Not NodePort

**Check:**
```bash
kubectl get svc -n dhakacart dhakacart-frontend-service
```

**If still ClusterIP:**
```bash
kubectl patch svc dhakacart-frontend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'
```

---

### Issue 3: Wrong Port in Target Group

**Check NodePort:**
```bash
kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}'
```

**Update target group** with correct port.

---

### Issue 4: Security Group Blocking

**Check security group rules:**
- Inbound: Allow TCP port 30080 from Load Balancer SG
- Outbound: Allow all (default)

---

## Verification Checklist

- [ ] Frontend service is `NodePort` type
- [ ] NodePort number obtained (e.g., 30080)
- [ ] Target group has worker nodes registered
- [ ] Target group health checks are healthy
- [ ] Security group allows port 30080
- [ ] Load Balancer listener configured (Port 80)
- [ ] Website accessible in browser

---

## Expected Result

After fixing:
- ✅ Target group shows healthy targets
- ✅ Website loads in browser
- ✅ No 502 error

---

**Last Updated**: 2024-11-30  
**Status**: Ready to Fix ✅

