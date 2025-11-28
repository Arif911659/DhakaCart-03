# 🏠 Local Kubernetes Setup (AWS Permission সমস্যার জন্য)

## সমস্যা:
AWS account এ EC2 instance তৈরি করার permission নেই।

## ✅ Solution: Local Kubernetes

### Option A: Minikube (সবচেয়ে সহজ)

```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --memory=4096 --cpus=2

# Check status
kubectl get nodes
```

### Option B: Kind (Kubernetes in Docker)

```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --name dhakacart

# Check status
kubectl cluster-info
```

### Option C: K3s (Lightweight Kubernetes)

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Check status
sudo k3s kubectl get nodes
```

---

## 🚀 Deploy DhakaCart (Local Kubernetes)

### 1. Start Minikube:
```bash
minikube start --memory=4096 --cpus=2
```

### 2. Deploy Application:
```bash
cd /home/arif/DhakaCart-03
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
```

### 3. Access Application:
```bash
# Get service URL
minikube service dhakacart-frontend -n dhakacart --url

# Or use port forwarding
kubectl port-forward -n dhakacart svc/dhakacart-frontend 3000:80
```

### 4. Open in Browser:
```
http://localhost:3000
```

---

## 📊 Comparison:

| Feature | AWS Cloud | Local (Minikube) |
|---------|-----------|------------------|
| **Cost** | $7-10/day | ✅ Free |
| **Internet Access** | ✅ Public URL | ❌ localhost only |
| **Performance** | High | Medium |
| **Setup Time** | 10-15 min | 5 min |
| **AWS Permission** | ❌ Required | ✅ Not needed |

---

## 🎯 Demo এর জন্য:

**Local Kubernetes (Minikube) ব্যবহার করুন:**
- ✅ Free
- ✅ Fast setup
- ✅ No AWS permission needed
- ✅ Perfect for demo/presentation

**AWS এর জন্য:**
- Admin থেকে permission নিতে হবে
- অথবা অন্য AWS account ব্যবহার করতে হবে

---

## 🔧 Quick Start:

```bash
# 1. Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 2. Start Cluster
minikube start

# 3. Deploy DhakaCart
kubectl apply -f k8s/ --recursive

# 4. Access
minikube service dhakacart-frontend -n dhakacart
```

---

## ✅ Recommendation:

**Demo/Presentation:** Use Minikube (local)  
**Production:** Need AWS permission from admin

