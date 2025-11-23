# 🚨 Quick Fix - Frontend Error Loading Products
**Date:** 2025-01-27  
**Issue:** Frontend shows "পণ্য লোড করতে সমস্যা হয়েছে" (Error loading products)

---

## 🐛 The Problem

The frontend is trying to connect to `http://localhost:5000/api`, but:
- ❌ The frontend runs in your **browser** (on your computer)
- ❌ `localhost:5000` refers to **your computer**, not the server
- ❌ The backend is on the **EC2 instance** (13.212.149.147)

---

## ✅ Quick Fix (2 Minutes)

### Option 1: Use Load Balancer URL (Recommended)

**Step 1: Get Load Balancer URL**
```bash
cd terraform
terraform output load_balancer_dns
```

**Step 2: SSH into EC2**
```bash
ssh -i terraform/dhakacart-key.pem ubuntu@13.212.149.147
```

**Step 3: Update Docker Compose**
```bash
cd /opt/dhakacart
nano docker-compose.yml
```

**Find this line (around line 101):**
```yaml
REACT_APP_API_URL: http://localhost:5000/api
```

**Replace with (use your load balancer DNS):**
```yaml
REACT_APP_API_URL: http://dhakacart-alb-xxxxx.ap-southeast-1.elb.amazonaws.com:8080/api
```

**Or use instance IP directly:**
```yaml
REACT_APP_API_URL: http://13.212.149.147:5000/api
```

**Step 4: Restart Frontend**
```bash
docker-compose restart frontend
# Wait 30 seconds
docker-compose logs frontend
```

**Step 5: Refresh Browser**
Open: `http://13.212.149.147:3000` and refresh!

---

### Option 2: Quick Test - Use Instance IP Directly

**SSH into EC2:**
```bash
ssh -i terraform/dhakacart-key.pem ubuntu@13.212.149.147
```

**Update environment variable:**
```bash
cd /opt/dhakacart
docker-compose exec frontend sh -c 'export REACT_APP_API_URL=http://13.212.149.147:5000/api'
docker-compose restart frontend
```

**Actually, better - edit docker-compose.yml:**
```bash
cd /opt/dhakacart
sed -i 's|REACT_APP_API_URL: http://localhost:5000/api|REACT_APP_API_URL: http://13.212.149.147:5000/api|g' docker-compose.yml
docker-compose down
docker-compose up -d
```

---

## 🔍 Verify Backend is Working

**SSH into EC2 and test:**
```bash
# Test backend health
curl http://localhost:5000/health

# Test products endpoint
curl http://localhost:5000/api/products

# Check if backend container is running
docker ps | grep backend

# Check backend logs
docker logs dhakacart-backend
```

**If backend is not running:**
```bash
cd /opt/dhakacart
docker-compose logs backend
docker-compose restart backend
```

---

## 🎯 Expected Result

After fixing:
- ✅ Frontend loads at: `http://13.212.149.147:3000`
- ✅ Products load successfully
- ✅ No error message
- ✅ Can add items to cart

---

## 📝 What I Updated in Terraform

I updated the Terraform code to automatically use the load balancer URL, but:
- ⚠️ **Existing instances** need to be updated manually (see Quick Fix above)
- ✅ **New instances** will use the correct URL automatically

---

## 🔄 For New Deployments

After updating Terraform, new instances will automatically use:
```yaml
REACT_APP_API_URL: http://<load-balancer-dns>:8080/api
```

**But existing instances need manual update!**

---

## ✅ Summary

**Problem:** Frontend uses `localhost:5000` which doesn't work from browser

**Quick Fix:** 
1. SSH into EC2
2. Update `docker-compose.yml` - change `localhost:5000` to `13.212.149.147:5000`
3. Restart frontend container
4. Refresh browser

**Time:** 2 minutes

**Status:** ✅ **Fixed in Terraform for future deployments**

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27

