# WebSocket Connection Timeout - Troubleshooting Guide

**তারিখ:** ৫ ডিসেম্বর, ২০২৫  
**সমস্যা:** Frontend WebSocket connections failing with `NS_ERROR_NET_TIMEOUT`

---

## 🔍 Problem Analysis

### Error Details:
```
Firefox can't establish a connection to the server at 
ws://dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com:3000/ws
```

### Root Causes:

1. **Wrong Port:** Frontend trying to connect to port 3000, but ALB only listens on port 80
2. **No WebSocket Support:** ALB target group doesn't have WebSocket protocol support enabled
3. **Frontend Configuration:** Frontend might be using development mode (React dev server) instead of production (Nginx)

---

## ✅ Solutions

### Solution 1: Fix ALB Configuration (Terraform)

ALB target group এ WebSocket support enable করতে হবে:

```hcl
# Target Group with WebSocket support
resource "aws_lb_target_group" "app" {
  name     = "${var.cluster_name}-tg"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Enable WebSocket support
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = "30080"
    protocol            = "HTTP"
    matcher             = "200-399"
  }
}
```

**Apply changes:**
```bash
cd terraform/simple-k8s
terraform apply
```

### Solution 2: Fix Frontend WebSocket URL

Frontend code এ WebSocket URL ঠিক করতে হবে:

**Current (Wrong):**
```javascript
ws://dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com:3000/ws
```

**Correct:**
```javascript
// Use port 80 (default HTTP/WS port)
ws://dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com/ws

// Or use wss:// for secure WebSocket (if HTTPS enabled)
wss://dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com/ws
```

### Solution 3: Check Frontend Deployment

Frontend production build (Nginx) ব্যবহার করছে কিনা verify করুন:

```bash
# Check frontend pods
kubectl get pods -n dhakacart -l app=dhakacart-frontend

# Check container image
kubectl describe pod <pod-name> -n dhakacart | grep Image

# Should be: arifhossaincse22/dhakacart-frontend:v1.0.1 (production with Nginx)
```

**If using development image:**
- Frontend container port 3000 এ React dev server চালাচ্ছে
- Production এ Nginx port 80 এ serve করবে

---

## 🔧 Quick Fixes

### Fix 1: Update ALB Target Group (AWS Console)

1. AWS Console → EC2 → Target Groups
2. Select your target group
3. **Attributes** tab → Edit
4. Enable:
   - **Stickiness:** Disabled (for WebSocket)
   - **Deregistration delay:** 30 seconds
5. Save

### Fix 2: Update Frontend ConfigMap

WebSocket URL update করুন:

```bash
# Get current ConfigMap
kubectl get configmap dhakacart-config -n dhakacart -o yaml

# Update REACT_APP_API_URL (remove port 3000)
kubectl patch configmap dhakacart-config -n dhakacart --type merge -p '{
  "data": {
    "REACT_APP_API_URL": "http://dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com/api"
  }
}'

# Restart frontend pods
kubectl rollout restart deployment/dhakacart-frontend -n dhakacart
```

### Fix 3: Add WebSocket Route in Nginx (if needed)

Frontend Nginx config এ WebSocket support যোগ করুন:

```nginx
# WebSocket support
location /ws {
    proxy_pass http://dhakacart-backend-service:5000/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400;
}
```

---

## 🧪 Testing

### Test 1: Check ALB Health
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-southeast-1
```

### Test 2: Test WebSocket Connection
```bash
# Using wscat (install: npm install -g wscat)
wscat -c ws://dhakacart-k8s-alb-329362090.ap-southeast-1.elb.amazonaws.com/ws

# Should connect successfully
```

### Test 3: Check Frontend Logs
```bash
# Check frontend pod logs
kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=50

# Look for WebSocket connection errors
```

---

## 📋 Verification Checklist

- [ ] ALB target group has WebSocket support enabled
- [ ] Frontend WebSocket URL uses port 80 (not 3000)
- [ ] Frontend is using production build (Nginx, not React dev server)
- [ ] Nginx config has WebSocket proxy settings
- [ ] Backend service supports WebSocket on `/ws` endpoint
- [ ] Security groups allow traffic on port 30080 (NodePort)

---

## 🚨 Common Issues

### Issue 1: Frontend Still Using Port 3000

**Symptom:** Browser console shows `ws://...:3000/ws` connection attempts

**Solution:**
- Check frontend code for hardcoded port 3000
- Update environment variables
- Rebuild and redeploy frontend

### Issue 2: ALB Not Forwarding WebSocket

**Symptom:** Connection times out even with correct URL

**Solution:**
- Verify ALB target group attributes
- Check security groups allow traffic
- Verify backend service is running

### Issue 3: Backend Not Supporting WebSocket

**Symptom:** Connection established but immediately closes

**Solution:**
- Check backend code for WebSocket support
- Verify backend service exposes `/ws` endpoint
- Check backend logs for errors

---

## 📚 References

- [AWS ALB WebSocket Support](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-websocket.html)
- [Kubernetes Service Types](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Nginx WebSocket Proxy](https://nginx.org/en/docs/http/websocket.html)

---

**Status:** Active Issue  
**Priority:** High  
**Last Updated:** ৫ ডিসেম্বর, ২০২৫

