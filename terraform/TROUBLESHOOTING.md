# 🔧 Troubleshooting Guide - Frontend Can't Load Products
**Date:** 2025-01-27  
**Issue:** Frontend shows error "পণ্য লোড করতে সমস্যা হয়েছে" (Error loading products)

---

## 🐛 The Problem

The frontend is trying to connect to `http://localhost:5000/api`, but:
- ❌ `localhost` in the browser refers to the user's computer, not the server
- ❌ The backend is on the EC2 instance, not the user's computer
- ❌ Browser can't reach `localhost:5000` on the server

---

## ✅ Solution: Update API URL

The frontend needs to use the **load balancer URL** or **EC2 instance IP** instead of `localhost`.

### Option 1: Use Load Balancer URL (Recommended)

Update `user_data.sh` to use the load balancer URL:

```bash
REACT_APP_API_URL: http://<load-balancer-dns>/api
```

### Option 2: Use EC2 Instance IP

Update `user_data.sh` to use the instance's public IP:

```bash
REACT_APP_API_URL: http://<ec2-instance-ip>:5000/api
```

### Option 3: Use Relative URLs (Best for Production)

Configure nginx to proxy API requests (already configured in nginx.conf).

---

## 🔍 Quick Fix Steps

### Step 1: Get Load Balancer URL

```bash
cd terraform
terraform output load_balancer_dns
```

**Example output:** `dhakacart-alb-123456789.ap-southeast-1.elb.amazonaws.com`

### Step 2: SSH into EC2 Instance

```bash
ssh -i terraform/dhakacart-key.pem ubuntu@<ec2-instance-ip>
```

### Step 3: Update Docker Compose

```bash
cd /opt/dhakacart
nano docker-compose.yml
```

**Change this line:**
```yaml
REACT_APP_API_URL: http://localhost:5000/api
```

**To (using load balancer):**
```yaml
REACT_APP_API_URL: http://dhakacart-alb-123456789.ap-southeast-1.elb.amazonaws.com/api
```

**Or (using instance IP):**
```yaml
REACT_APP_API_URL: http://13.212.149.147:5000/api
```

### Step 4: Restart Containers

```bash
docker-compose down
docker-compose up -d
```

**Wait 30 seconds, then refresh the browser!** ✅

---

## 🔧 Better Solution: Update Terraform

I'll update the Terraform code to automatically use the load balancer URL.

---

## 📋 Check Backend is Running

### SSH into EC2 and check:

```bash
# Check if containers are running
docker ps

# Check backend logs
docker logs dhakacart-backend

# Test backend directly
curl http://localhost:5000/health
curl http://localhost:5000/api/products
```

**If backend is not running:**
```bash
cd /opt/dhakacart
docker-compose logs backend
docker-compose restart backend
```

---

## 🔍 Common Issues

### Issue 1: Backend Not Running
**Check:**
```bash
docker ps | grep backend
```

**Fix:**
```bash
cd /opt/dhakacart
docker-compose restart backend
docker-compose logs backend
```

### Issue 2: Database Not Ready
**Check:**
```bash
docker logs dhakacart-db
```

**Fix:**
```bash
docker-compose restart database
# Wait 30 seconds
docker-compose restart backend
```

### Issue 3: Security Group Blocking Port 5000
**Check:** AWS Console → EC2 → Security Groups
- Load balancer security group should allow port 80
- Web server security group should allow port 5000 from load balancer

---

## ✅ Quick Test

### Test Backend from EC2:
```bash
curl http://localhost:5000/api/products
```

### Test Backend from Load Balancer:
```bash
curl http://<load-balancer-dns>/api/products
```

### Test from Browser:
Open: `http://<load-balancer-dns>/api/products`

**Should return JSON with products!** ✅

---

## 🎯 Expected Behavior

### Working Setup:
1. ✅ Frontend accessible at: `http://<load-balancer-dns>`
2. ✅ Backend accessible at: `http://<load-balancer-dns>:8080/api` (or via nginx proxy)
3. ✅ Frontend can fetch products from backend
4. ✅ No errors in browser console

---

## 📝 Summary

**Problem:** Frontend uses `localhost:5000` which doesn't work from browser

**Solution:** Update `REACT_APP_API_URL` to use load balancer URL or instance IP

**Quick Fix:** SSH into EC2, update docker-compose.yml, restart containers

**Better Fix:** Update Terraform to automatically set correct URL

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27

