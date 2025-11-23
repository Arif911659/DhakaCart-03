# 🔧 Docker Network Solution - Frontend Backend Communication
**Date:** 2025-01-27  
**সমস্যা:** Frontend এবং Backend Docker container-এ, কিন্তু browser থেকে API call করতে হচ্ছে

---

## 🎯 সমস্যা

আপনি ঠিক বলেছেন - Frontend এবং Backend Docker container-এ চলছে। কিন্তু:

1. **Frontend React app** browser-এ run করে (client-side)
2. Browser-এর JavaScript code backend-এ API call করে
3. Browser Docker network-এ access করতে পারে না
4. তাই browser-কে backend-এ reach করতে public IP বা proxy লাগে

---

## ✅ সমাধান: Nginx Proxy ব্যবহার

### Option 1: Production Build with Nginx (সবচেয়ে ভালো)

Frontend image **production target** দিয়ে build করুন (nginx সহ):

```bash
cd frontend
docker build --target production -t arifhossaincse22/dhakacart-frontend:latest .
docker push arifhossaincse22/dhakacart-frontend:latest
```

**nginx.conf** already configured:
- `/api/` requests → `backend:5000/api/` (Docker network)
- Frontend uses relative URL: `/api`

**Result:**
- ✅ Browser → Frontend (port 3000)
- ✅ Browser → `/api/products` → Nginx proxies → `backend:5000/api/products`
- ✅ সব Docker network-এ, public IP লাগবে না!

---

### Option 2: Development Server with Proxy (Quick Fix)

যদি production build করতে না পারেন:

**SSH into EC2:**
```bash
ssh -i terraform/dhakacart-key.pem ubuntu@13.212.149.147
cd /opt/dhakacart
```

**Add nginx as reverse proxy:**
```bash
# Install nginx
sudo apt-get update
sudo apt-get install -y nginx

# Create nginx config
sudo tee /etc/nginx/sites-available/dhakacart <<EOF
server {
    listen 80;
    server_name _;

    # Proxy API to backend container
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_set_header Host \$host;
    }

    # Proxy frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/dhakacart /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Then access via:** `http://13.212.149.147` (port 80)

---

### Option 3: Update Frontend Code (Simplest)

Frontend code update করুন relative URL ব্যবহার করতে:

**App.js-এ:**
```javascript
// Use relative URL - same origin
const API_URL = '/api';
```

**Then rebuild frontend image:**
```bash
cd frontend
docker build --target production -t arifhossaincse22/dhakacart-frontend:latest .
docker push arifhossaincse22/dhakacart-frontend:latest
```

**nginx.conf** already proxies `/api/` to `backend:5000/api/`

---

## 🔍 Current Setup Check

### Check what's running:
```bash
ssh -i terraform/dhakacart-key.pem ubuntu@13.212.149.147
docker ps
docker-compose ps
```

### Check frontend image:
```bash
docker inspect dhakacart-frontend | grep -i cmd
```

**If CMD is `npm start`** → Development mode (no nginx)  
**If CMD is `nginx`** → Production mode (has nginx) ✅

---

## ✅ Recommended Solution

**Step 1: Rebuild Frontend with Production Target**

```bash
cd frontend
docker build --target production -t arifhossaincse22/dhakacart-frontend:latest .
docker push arifhossaincse22/dhakacart-frontend:latest
```

**Step 2: Update docker-compose.yml in EC2**

```bash
ssh -i terraform/dhakacart-key.pem ubuntu@13.212.149.147
cd /opt/dhakacart
nano docker-compose.yml
```

**Change:**
```yaml
frontend:
  ports:
    - "3000:80"  # nginx uses port 80
  environment:
    REACT_APP_API_URL: /api  # Relative URL
```

**Step 3: Restart**
```bash
docker-compose pull frontend
docker-compose up -d --force-recreate frontend
```

---

## 📝 Summary

**সমস্যা:** Browser Docker network access করতে পারে না

**সমাধান:** 
1. ✅ Nginx proxy ব্যবহার করুন (production build)
2. ✅ Frontend relative URL ব্যবহার করুন (`/api`)
3. ✅ Nginx `/api/` → `backend:5000/api/` proxy করবে

**Result:** 
- ✅ সব Docker network-এ
- ✅ Public IP লাগবে না
- ✅ Browser → Nginx → Backend (Docker network)

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27

