# 🔧 Fix API URL Error - ERR_NAME_NOT_RESOLVED

**Error**: `ERR_NAME_NOT_RESOLVED` for `http://dhakacart-k8s-alb-987654321...`  
**Issue**: ConfigMap has wrong Load Balancer URL  
**Solution**: Update ConfigMap with correct URL

---

## Quick Fix

### Master-1 এ এই commands run করুন:

```bash
# 1. Get current Load Balancer URL (from AWS Console or use this)
LB_URL="dhakacart-k8s-alb-1098869932.ap-southeast-1.elb.amazonaws.com"

# 2. Update ConfigMap
kubectl get configmap dhakacart-config -n dhakacart -o yaml > /tmp/dhakacart-config.yaml
sed -i "s|REACT_APP_API_URL:.*|REACT_APP_API_URL: \"http://$LB_URL/api\"|" /tmp/dhakacart-config.yaml
kubectl apply -f /tmp/dhakacart-config.yaml
rm /tmp/dhakacart-config.yaml

# 3. Verify update
kubectl get configmap dhakacart-config -n dhakacart -o jsonpath='{.data.REACT_APP_API_URL}'
echo ""

# 4. Restart frontend pods to pick up new config
kubectl rollout restart deployment dhakacart-frontend -n dhakacart

# 5. Wait and check
echo "Waiting for pods to restart..."
sleep 60
kubectl get pods -n dhakacart -l app=dhakacart-frontend
```

---

## Alternative: Use Update Script

**Your Computer এ:**

```bash
cd /home/arif/DhakaCart-03

# Update ConfigMap with correct Load Balancer URL
./update-configmap-with-lb.sh dhakacart-k8s-alb-1098869932.ap-southeast-1.elb.amazonaws.com
```

---

## Get Correct Load Balancer URL

### Method 1: AWS Console
1. AWS Console → EC2 → Load Balancers
2. Find `dhakacart-k8s-alb-XXXXX`
3. Copy DNS name

### Method 2: Master-1 এ
```bash
# If you have ingress controller
kubectl get ingress -A -o jsonpath="{range .items[*]}{.status.loadBalancer.ingress[0].hostname}{'\n'}{end}"

# Or check AWS Console manually
```

---

## Verify Fix

After updating:

1. **Check ConfigMap:**
   ```bash
   kubectl get configmap dhakacart-config -n dhakacart -o jsonpath='{.data.REACT_APP_API_URL}'
   ```
   Should show: `http://dhakacart-k8s-alb-1098869932.../api`

2. **Check Frontend Pods:**
   ```bash
   kubectl get pods -n dhakacart -l app=dhakacart-frontend
   ```
   Should show new pods (restarted)

3. **Browser Test:**
   - Refresh page
   - No more `ERR_NAME_NOT_RESOLVED`
   - API calls should work

---

## Current vs Correct URL

**Current (Wrong):**
```
http://dhakacart-k8s-alb-987654321.ap-southeast-1.elb.amazonaws.com/api
```

**Correct:**
```
http://dhakacart-k8s-alb-1098869932.ap-southeast-1.elb.amazonaws.com/api
```

---

**Last Updated**: 2024-11-30

