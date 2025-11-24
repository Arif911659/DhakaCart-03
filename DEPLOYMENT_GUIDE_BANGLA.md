# 🚀 DhakaCart Deployment Guide - ধাপে ধাপে গাইড

**তারিখ:** ২৩ নভেম্বর, ২০২৪  
**লক্ষ্য:** Non-coder ব্যক্তিদের জন্য সহজ বাংলায় deployment guide  
**প্রজেক্ট:** DhakaCart E-Commerce Platform

---

## 📋 Table of Contents

1. [প্রথমে যা জানা দরকার](#প্রথমে-যা-জানা-দরকার)
2. [Deployment Options](#deployment-options)
3. [Option 1: Local Development (সবচেয়ে সহজ)](#option-1-local-development-সবচেয়ে-সহজ)
4. [Option 2: Production with Docker Compose](#option-2-production-with-docker-compose)
5. [Option 3: Kubernetes Deployment](#option-3-kubernetes-deployment)
6. [Option 4: Cloud Deployment with Terraform](#option-4-cloud-deployment-with-terraform)
7. [Option 5: Automated Deployment with Ansible](#option-5-automated-deployment-with-ansible)
8. [Monitoring & Logging Setup](#monitoring--logging-setup)
9. [Backup System Setup](#backup-system-setup)
10. [Troubleshooting](#troubleshooting)

---

## প্রথমে যা জানা দরকার

### 🎯 এই Guide কেন?

আপনি যদি coding না জানেন, তাহলে এই guide আপনার জন্য। এখানে প্রতিটা command এর ব্যাখ্যা আছে, কী করছে সেটা বুঝিয়ে বলা আছে।

### 📦 আপনার কাছে যা আছে

```
DhakaCart-03/
├── frontend/          → React application
├── backend/           → Node.js API
├── database/          → PostgreSQL setup
├── docker-compose.yml → Local deployment
├── docker-compose.prod.yml → Production deployment
├── k8s/               → Kubernetes files
├── terraform/        → Cloud infrastructure
├── ansible/          → Automation scripts
├── monitoring/       → Prometheus + Grafana
├── logging/          → Loki logging
├── scripts/          → Backup scripts
└── security/         → Security tools
```

### 🔧 যা যা লাগবে

#### Minimum Requirements:
- **Operating System:** Linux (Ubuntu 20.04+), macOS, বা Windows with WSL2
- **RAM:** কমপক্ষে 8GB (16GB recommended)
- **Disk Space:** কমপক্ষে 20GB free space
- **Internet:** Stable connection (Docker images download করতে হবে)

#### Software যা install করতে হবে:

1. **Docker** - Container চালানোর জন্য
2. **Docker Compose** - Multiple containers manage করার জন্য
3. **Git** - Code download করার জন্য (যদি GitHub থেকে নেন)
4. **kubectl** - শুধুমাত্র Kubernetes deploy করতে হলে
5. **Terraform** - শুধুমাত্র Cloud deploy করতে হলে
6. **Ansible** - শুধুমাত্র Ansible automation ব্যবহার করতে হলে

---

## Deployment Options

আপনার কাছে **৫টি option** আছে deployment এর জন্য:

### Option 1: Local Development (সবচেয়ে সহজ) ⭐
- **কখন ব্যবহার করবেন:** Testing, learning, development
- **সময় লাগবে:** ৫-১০ মিনিট
- **কী লাগবে:** শুধু Docker Desktop
- **কঠিনতা:** ⭐ (সবচেয়ে সহজ)

### Option 2: Production with Docker Compose
- **কখন ব্যবহার করবেন:** Single server এ production deploy
- **সময় লাগবে:** ১০-১৫ মিনিট
- **কী লাগবে:** Docker + Docker Compose
- **কঠিনতা:** ⭐⭐ (সহজ)

### Option 3: Kubernetes Deployment
- **কখন ব্যবহার করবেন:** Production environment, auto-scaling চাইলে
- **সময় লাগবে:** ৩০-৪৫ মিনিট
- **কী লাগবে:** Kubernetes cluster
- **কঠিনতা:** ⭐⭐⭐⭐ (কঠিন)

### Option 4: Cloud Deployment with Terraform
- **কখন ব্যবহার করবেন:** AWS/GCP/Azure এ deploy করতে চাইলে
- **সময় লাগবে:** ৪৫-৬০ মিনিট
- **কী লাগবে:** Cloud account + Terraform
- **কঠিনতা:** ⭐⭐⭐⭐ (কঠিন)

### Option 4: HA Kubernetes Cluster with Terraform (নতুন!) ⭐⭐⭐⭐⭐
- **কখন ব্যবহার করবেন:** Production-ready HA Kubernetes cluster চাইলে
- **সময় লাগবে:** ১৫-২০ মিনিট (automated)
- **কী লাগবে:** AWS account + Terraform
- **কঠিনতা:** ⭐⭐⭐⭐ (Advanced, কিন্তু fully automated)

### Option 5: Cloud Deployment with Terraform (Simple)
- **কখন ব্যবহার করবেন:** AWS/GCP/Azure এ simple deployment
- **সময় লাগবে:** ৪৫-৬০ মিনিট
- **কী লাগবে:** Cloud account + Terraform
- **কঠিনতা:** ⭐⭐⭐⭐ (কঠিন)

### Option 6: Automated Deployment with Ansible
- **কখন ব্যবহার করবেন:** Multiple servers automate করতে চাইলে
- **সময় লাগবে:** ৩০-৪৫ মিনিট
- **কী লাগবে:** Ansible + Server access
- **কঠিনতা:** ⭐⭐⭐ (মাঝারি)

---

## Option 1: Local Development (সবচেয়ে সহজ)

### 🎯 এই Option দিয়ে কী হবে?

আপনার নিজের কম্পিউটারে application চালু হবে। এটা testing এবং learning এর জন্য perfect।

### ধাপ ১: Docker Install করুন

#### Windows এ:
1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) download করুন
2. Installer run করুন
3. Computer restart করুন
4. Docker Desktop open করুন এবং wait করুন startup complete হতে

#### macOS এ:
1. [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop) download করুন
2. Installer run করুন
3. Docker Desktop open করুন

#### Linux (Ubuntu) এ:
```bash
# Terminal খুলুন এবং এই commands run করুন:

# Step 1: Update system
sudo apt update

# Step 2: Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Step 3: Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Step 4: Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 5: Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Step 6: Add your user to docker group (so you don't need sudo)
sudo usermod -aG docker $USER

# Step 7: Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Step 8: Verify installation
docker --version
docker compose version
```

**✅ Check করুন:** `docker --version` command run করলে version number দেখাবে

### ধাপ ২: Project Folder এ যান

```bash
# Terminal/Command Prompt খুলুন

# Project folder এ যান
cd /home/arif/DhakaCart-03

# বা যদি অন্য path এ থাকে
cd /path/to/DhakaCart-03

# Check করুন সব files আছে কিনা
ls -la
```

**✅ Check করুন:** `docker-compose.yml` file টা আছে কিনা

### ধাপ ৩: Environment Variables Setup করুন

```bash
# Project root folder এ .env file তৈরি করুন
nano .env
```

**এই content টা paste করুন:**
```env
# Database Configuration
DB_USER=dhakacart
DB_PASSWORD=dhakacart123
DB_NAME=dhakacart_db
DB_HOST=database
DB_PORT=5432

# Application Configuration
NODE_ENV=development
PORT=5000

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
```

**Save করুন:** `Ctrl + O` (save), তারপর `Enter`, তারপর `Ctrl + X` (exit)

**💡 ব্যাখ্যা:** এই file এ সব configuration আছে যা application ব্যবহার করবে।

### ধাপ ৪: Application Start করুন

```bash
# সব services start করুন
docker compose up -d
```

**💡 এই command কী করছে:**
- `docker compose` = Docker Compose tool ব্যবহার করছে
- `up` = সব containers start করছে
- `-d` = Background এ run করছে (detached mode)

**⏱️ অপেক্ষা করুন:** ১-২ মিনিট (প্রথমবার images download হতে সময় লাগবে)

### ধাপ ৫: Status Check করুন

```bash
# সব containers running আছে কিনা check করুন
docker compose ps
```

**✅ Expected Output:**
```
NAME                  STATUS          PORTS
dhakacart-db          Up (healthy)    0.0.0.0:5432->5432/tcp
dhakacart-redis       Up (healthy)    0.0.0.0:6379->6379/tcp
dhakacart-backend     Up              0.0.0.0:5000->5000/tcp
dhakacart-frontend    Up              0.0.0.0:3000->80/tcp
```

**যদি সব "Up" দেখায়, তাহলে ✅ Success!**

### ধাপ ৬: Application Access করুন

#### Browser এ খুলুন:

1. **Frontend (Website):**
   ```
   http://localhost:3000
   ```

2. **Backend API (Test করার জন্য):**
   ```
   http://localhost:5000/api/products
   ```

3. **Health Check:**
   ```
   http://localhost:5000/health
   ```

**✅ যদি website খুলে, তাহলে সব ঠিক আছে!**

### ধাপ ৭: Logs দেখুন (যদি সমস্যা হয়)

```bash
# সব services এর logs দেখুন
docker compose logs

# শুধু backend এর logs
docker compose logs backend

# Real-time logs (live update)
docker compose logs -f backend
```

### ধাপ ৮: Application Stop করুন (যখন কাজ শেষ)

```bash
# সব services stop করুন
docker compose down

# Data সহ সব delete করতে চাইলে (সাবধান!)
docker compose down -v
```

**💡 ব্যাখ্যা:**
- `down` = সব containers stop করে
- `-v` = volumes (database data) delete করে

---

## Option 2: Production with Docker Compose

### 🎯 এই Option দিয়ে কী হবে?

একটা production-ready setup যেখানে সব কিছু optimized হবে।

### ধাপ ১: Production File Check করুন

```bash
# Production docker-compose file আছে কিনা check করুন
ls -la docker-compose.prod.yml
```

### ধাপ ২: Environment Variables Setup করুন

```bash
# Production .env file তৈরি করুন
nano .env.prod
```

**এই content টা paste করুন:**
```env
# Database Configuration (Production)
DB_USER=dhakacart
DB_PASSWORD=dhakacart123  # ⚠️ Production এ strong password ব্যবহার করুন!
DB_NAME=dhakacart_db
DB_HOST=database
DB_PORT=5432

# Application Configuration
NODE_ENV=production
PORT=5000

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
```

### ধাপ ৩: Production Mode এ Start করুন

```bash
# Production file ব্যবহার করে start করুন
docker compose -f docker-compose.prod.yml up -d
```

**💡 ব্যাখ্যা:**
- `-f docker-compose.prod.yml` = Production file ব্যবহার করছে

### ধাপ ৪: Status Check করুন

```bash
# সব containers running আছে কিনা
docker compose -f docker-compose.prod.yml ps
```

### ধাপ ৫: Access করুন

```
Frontend: http://localhost:3000
Backend:  http://localhost:5000/api/products
```

---

## Option 3: Kubernetes Deployment

### ⚠️ এই Option Advanced - শুধু যদি Kubernetes cluster থাকে

### Prerequisites:

1. **Kubernetes Cluster** (Minikube, EKS, GKE, AKS, বা local cluster)
2. **kubectl** installed
3. **kubectl** configured (cluster access)

### kubectl Install করুন:

#### Linux:
```bash
# kubectl download করুন
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install করুন
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

#### macOS:
```bash
# Homebrew দিয়ে
brew install kubectl

# Verify
kubectl version --client
```

#### Windows:
1. [kubectl download](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) করুন
2. PATH এ add করুন

### ধাপ ১: Kubernetes Cluster Check করুন

```bash
# Cluster connection check করুন
kubectl cluster-info

# Nodes check করুন
kubectl get nodes
```

**✅ যদি nodes দেখায়, তাহলে connection ঠিক আছে**

### ধাপ ২: Namespace Create করুন

```bash
# Project folder এ যান
cd /home/arif/DhakaCart-03/k8s

# Namespace create করুন
kubectl apply -f namespace.yaml
```

### ধাপ ৩: Secrets Create করুন

```bash
# Secrets folder এ যান
cd secrets

# সব secrets apply করুন
kubectl apply -f .

# বা individually
kubectl apply -f database-secret.yaml
kubectl apply -f redis-secret.yaml
kubectl apply -f app-secret.yaml
```

**💡 ব্যাখ্যা:** Secrets = passwords এবং sensitive data store করে

### ধাপ ৪: ConfigMaps Apply করুন

```bash
# ConfigMaps folder এ যান
cd ../configmaps

# সব configmaps apply করুন
kubectl apply -f .
```

**💡 ব্যাখ্যা:** ConfigMaps = application configuration store করে

### ধাপ ৫: Volumes Create করুন

```bash
# Volumes folder এ যান
cd ../volumes

# সব volumes apply করুন
kubectl apply -f .
```

**💡 ব্যাখ্যা:** Volumes = database data store করার জন্য persistent storage

### ধাপ ৬: Deployments Apply করুন

```bash
# Deployments folder এ যান
cd ../deployments

# সব deployments apply করুন
kubectl apply -f .
```

**💡 ব্যাখ্যা:** Deployments = application containers run করবে

### ধাপ ৭: Services Apply করুন

```bash
# Services folder এ যান
cd ../services

# সব services apply করুন
kubectl apply -f .
```

**💡 ব্যাখ্যা:** Services = containers এর সাথে connect করার জন্য network endpoints

### ধাপ ৮: Auto-Scaling Setup করুন

```bash
# Root folder এ যান
cd ..

# HPA (Horizontal Pod Autoscaler) apply করুন
kubectl apply -f hpa.yaml
```

**💡 ব্যাখ্যা:** HPA = load বেশি হলে automatically more pods create করবে

### ধাপ ৯: Status Check করুন

```bash
# সব resources check করুন
kubectl get all -n dhakacart

# Pods check করুন
kubectl get pods -n dhakacart

# Services check করুন
kubectl get services -n dhakacart
```

**✅ সব pods "Running" status দেখালে Success!**

### ধাপ ১০: Access করুন

```bash
# Service URL পাওয়ার জন্য
kubectl get services -n dhakacart

# Port forwarding (local access)
kubectl port-forward -n dhakacart service/dhakacart-frontend 3000:80
kubectl port-forward -n dhakacart service/dhakacart-backend 5000:5000
```

**💡 ব্যাখ্যা:** Port forwarding = Kubernetes service কে local machine এ access করতে দেয়

### ধাপ ১১: Logs দেখুন

```bash
# Backend logs
kubectl logs -f -l app=dhakacart-backend -n dhakacart

# Frontend logs
kubectl logs -f -l app=dhakacart-frontend -n dhakacart
```

### ধাপ ১২: Scale করুন (যদি দরকার)

```bash
# Backend pods increase করুন
kubectl scale deployment dhakacart-backend -n dhakacart --replicas=5

# Frontend pods increase করুন
kubectl scale deployment dhakacart-frontend -n dhakacart --replicas=3
```

### Complete Guide:

বিস্তারিত guide আছে: `k8s/DEPLOYMENT_GUIDE.md` (1458 lines)

---

## Option 4: High-Availability Kubernetes Cluster with Terraform (নতুন!) ⭐⭐⭐⭐⭐

### 🎯 এই Option দিয়ে কী হবে?

একটা **fully automated High-Availability Kubernetes cluster** তৈরি হবে AWS এ। এটা production-ready এবং self-managed (kubeadm-based)।

### ✨ Features:

- ✅ **3 Master Nodes** - High Availability
- ✅ **2+ Worker Nodes** - Workload distribution
- ✅ **Internal Load Balancer** - Kubernetes API Server (port 6443)
- ✅ **Public Load Balancer** - Ingress traffic
- ✅ **Bastion Host** - Secure access
- ✅ **Multi-AZ Deployment** - 2-3 Availability Zones
- ✅ **Automated Setup** - cloud-init scripts
- ✅ **Calico CNI** - Automatically installed
- ✅ **Production-Ready** - Security groups and networking

### Prerequisites:

1. **AWS Account** with permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured
4. **kubectl** installed (optional, for cluster access)

### ধাপ ১: AWS Credentials Setup করুন

```bash
# AWS credentials configure করুন
aws configure

# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: ap-southeast-1
# Default output format: json
```

**💡 ব্যাখ্যা:** AWS services access করার জন্য credentials লাগবে

### ধাপ ২: HA Kubernetes Cluster Folder এ যান

```bash
# Project root থেকে
cd terraform/k8s-ha-cluster
```

**💡 ব্যাখ্যা:** এই folder এ সব HA cluster files আছে

### ধাপ ৩: Variables File তৈরি করুন

```bash
# Example file copy করুন
cp terraform.tfvars.example terraform.tfvars

# Edit করুন (optional - defaults আছে)
nano terraform.tfvars
```

**💡 ব্যাখ্যা:** এই file এ customization করতে পারেন (instance types, node counts ইত্যাদি)

### ধাপ ৪: Terraform Initialize করুন

```bash
# Terraform initialize করুন
terraform init
```

**💡 ব্যাখ্যা:** এই command plugins এবং modules download করবে

**✅ Expected Output:**
```
Terraform has been successfully initialized!
```

### ধাপ ৫: Plan দেখুন (কী কী create হবে)

```bash
# Infrastructure plan দেখুন
terraform plan
```

**💡 ব্যাখ্যা:** এই command দেখাবে কী কী resources create হবে, কিন্তু create করবে না

**⏱️ অপেক্ষা করুন:** ১-২ মিনিট (plan generate হতে)

**✅ Expected Output:**
```
Plan: XX to add, 0 to change, 0 to destroy.
```

### ধাপ ৬: Infrastructure Create করুন

```bash
# Infrastructure create করুন
terraform apply
```

**⚠️ সাবধান:** এই command run করলে AWS resources create হবে এবং charges apply হবে!

**Confirmation prompt এ `yes` type করুন**

**⏱️ অপেক্ষা করুন:** ১৫-২০ মিনিট (resources create হতে সময় লাগবে)

**💡 এই সময়ে কী হচ্ছে:**
1. VPC এবং subnets create হচ্ছে
2. Load Balancers create হচ্ছে
3. Security Groups create হচ্ছে
4. Master nodes install করছে Kubernetes
5. Worker nodes join করছে cluster এ
6. Calico CNI install হচ্ছে

### ধাপ ৭: Outputs দেখুন

```bash
# Created resources এর information দেখুন
terraform output
```

**✅ Key Outputs:**
- `api_server_endpoint` - Kubernetes API Server endpoint
- `bastion_ssh_command` - SSH command to connect to bastion
- `kubeconfig_command` - Command to get kubeconfig
- `ingress_lb_endpoint` - Public Load Balancer for Ingress

### ধাপ ৮: Bastion Host এ Connect করুন

```bash
# Output থেকে SSH command copy করুন
terraform output bastion_ssh_command

# বা manually
ssh -i dhakacart-k8s-ha-key.pem ubuntu@<bastion-ip>
```

**💡 ব্যাখ্যা:** Bastion host = secure gateway to access private nodes

### ধাপ ৯: Master Node এ Connect করুন

```bash
# Bastion থেকে master1 এ connect করুন
ssh -i dhakacart-k8s-ha-key.pem ubuntu@<master1-private-ip>
```

**💡 ব্যাখ্যা:** Master nodes private subnet এ আছে, তাই bastion দিয়ে access করতে হবে

### ধাপ ১০: Cluster Status Check করুন

```bash
# Nodes check করুন
kubectl get nodes

# Pods check করুন
kubectl get pods --all-namespaces

# Cluster info
kubectl cluster-info
```

**✅ Expected Output:**
```
NAME                    STATUS   ROLES           AGE   VERSION
master-1                Ready    control-plane   5m    v1.28.0
master-2                Ready    control-plane   5m    v1.28.0
master-3                Ready    control-plane   5m    v1.28.0
worker-1                 Ready    <none>          4m    v1.28.0
worker-2                 Ready    <none>          4m    v1.28.0
```

### ধাপ ১১: kubeconfig Local Machine এ Copy করুন

```bash
# Bastion থেকে local machine এ
scp -i dhakacart-k8s-ha-key.pem ubuntu@<bastion-ip>:~/.kube/config ~/.kube/config

# Permissions set করুন
chmod 600 ~/.kube/config
```

**💡 ব্যাখ্যা:** kubeconfig = Kubernetes cluster access করার জন্য configuration file

### ধাপ ১২: Local Machine থেকে Cluster Access করুন

```bash
# Cluster info দেখুন
kubectl cluster-info

# Nodes দেখুন
kubectl get nodes

# Test deployment করুন
kubectl create deployment nginx --image=nginx
kubectl get pods
```

**✅ যদি সব কাজ করে, তাহলে cluster ready!**

### ধাপ ১৩: Application Deploy করুন

```bash
# DhakaCart application deploy করুন
cd /home/arif/DhakaCart-03/k8s

# সব resources apply করুন
kubectl apply -f namespace.yaml
kubectl apply -f secrets/
kubectl apply -f configmaps/
kubectl apply -f volumes/
kubectl apply -f deployments/
kubectl apply -f services/
kubectl apply -f ingress/
```

### ধাপ ১৪: Ingress Access করুন

```bash
# Ingress Load Balancer endpoint পাওয়ার জন্য
terraform output ingress_lb_endpoint
```

**Browser এ এই URL open করুন**

### ধাপ ১৫: Infrastructure Destroy করুন (যখন test শেষ)

```bash
# ⚠️ সাবধান: এই command সব resources delete করবে!
terraform destroy
```

**Confirmation prompt এ `yes` type করুন**

### 📚 Complete Guide:

বিস্তারিত guide আছে: `terraform/k8s-ha-cluster/README.md`

### 💰 Cost Estimation:

Approximate monthly costs (ap-southeast-1):
- 3x t3.medium masters: ~$90
- 2x t3.medium workers: ~$60
- 1x t3.micro bastion: ~$7
- 3x NAT Gateways: ~$135
- 2x Load Balancers: ~$35
- **Total: ~$327/month** (excluding data transfer)

---

## Option 5: Cloud Deployment with Terraform (Simple)

### ⚠️ এই Option Advanced - Cloud account লাগবে

### Prerequisites:

1. **Cloud Account** (AWS, GCP, Azure)
2. **Terraform** installed
3. **Cloud Credentials** configured

### Terraform Install করুন:

#### Linux:
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# Unzip
unzip terraform_1.6.0_linux_amd64.zip

# Move to PATH
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

#### macOS:
```bash
# Homebrew দিয়ে
brew install terraform

# Verify
terraform version
```

#### Windows:
1. [Terraform download](https://www.terraform.io/downloads) করুন
2. PATH এ add করুন

### AWS Example (সবচেয়ে common):

### ধাপ ১: AWS Credentials Setup করুন

```bash
# AWS credentials configure করুন
aws configure

# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: us-east-1 (বা আপনার preferred region)
# Default output format: json
```

**💡 ব্যাখ্যা:** AWS services access করার জন্য credentials লাগবে

### ধাপ ২: Terraform Folder এ যান

```bash
cd /home/arif/DhakaCart-03/terraform
```

### ধাপ ৩: Variables File তৈরি করুন

```bash
# Example file copy করুন
cp terraform.tfvars.example terraform.tfvars

# Edit করুন
nano terraform.tfvars
```

**এই content টা customize করুন:**
```hcl
# AWS Configuration
aws_region = "us-east-1"
aws_access_key = "YOUR_ACCESS_KEY"
aws_secret_key = "YOUR_SECRET_KEY"

# Instance Configuration
instance_type = "t3.medium"
min_instances = 2
max_instances = 10

# Database Configuration
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
```

### ধাপ ৪: Terraform Initialize করুন

```bash
# Terraform initialize করুন (plugins download করবে)
terraform init
```

**💡 ব্যাখ্যা:** এই command প্রথমবার run করলে plugins এবং modules download করবে

### ধাপ ৫: Plan দেখুন (কী কী create হবে)

```bash
# Infrastructure plan দেখুন
terraform plan
```

**💡 ব্যাখ্যা:** এই command দেখাবে কী কী resources create হবে, কিন্তু create করবে না

### ধাপ ৬: Infrastructure Create করুন

```bash
# Infrastructure create করুন
terraform apply
```

**⚠️ সাবধান:** এই command run করলে cloud resources create হবে এবং charges apply হবে!

**Confirmation prompt এ `yes` type করুন**

**⏱️ অপেক্ষা করুন:** ১০-১৫ মিনিট (resources create হতে সময় লাগবে)

### ধাপ ৭: Outputs দেখুন

```bash
# Created resources এর information দেখুন
terraform output
```

**💡 ব্যাখ্যা:** এই command load balancer URL, database endpoint ইত্যাদি দেখাবে

### ধাপ ৮: Access করুন

```bash
# Load balancer URL পাওয়ার জন্য
terraform output load_balancer_url
```

**Browser এ এই URL open করুন**

### ধাপ ৯: Infrastructure Destroy করুন (যখন test শেষ)

```bash
# ⚠️ সাবধান: এই command সব resources delete করবে!
terraform destroy
```

**Confirmation prompt এ `yes` type করুন**

### Complete Guide:

বিস্তারিত guide আছে: `terraform/README.md`

---

## Option 6: Automated Deployment with Ansible

### ⚠️ এই Option Advanced - Server access লাগবে

### Prerequisites:

1. **Ansible** installed
2. **SSH access** to target servers
3. **Python** installed on target servers

### Ansible Install করুন:

#### Linux:
```bash
# Install Ansible
sudo apt update
sudo apt install -y ansible

# Verify
ansible --version
```

#### macOS:
```bash
# Homebrew দিয়ে
brew install ansible

# Verify
ansible --version
```

### ধাপ ১: Inventory File Setup করুন

```bash
# Ansible folder এ যান
cd /home/arif/DhakaCart-03/ansible

# Inventory file edit করুন
nano inventory/hosts.ini
```

**এই content টা customize করুন:**
```ini
[servers]
server1 ansible_host=192.168.1.100 ansible_user=ubuntu
server2 ansible_host=192.168.1.101 ansible_user=ubuntu

[servers:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**💡 ব্যাখ্যা:** Inventory = কোন servers এ deploy করবে সেটা define করে

### ধাপ ২: SSH Key Setup করুন

```bash
# SSH key generate করুন (যদি না থাকে)
ssh-keygen -t rsa -b 4096

# Public key server এ copy করুন
ssh-copy-id user@server-ip
```

### ধাপ ৩: Connection Test করুন

```bash
# Servers এ connection test করুন
ansible all -i inventory/hosts.ini -m ping
```

**✅ যদি "SUCCESS" দেখায়, তাহলে connection ঠিক আছে**

### ধাপ ৪: Server Provision করুন

```bash
# Servers setup করুন (Docker, dependencies install)
ansible-playbook -i inventory/hosts.ini playbooks/provision.yml
```

**💡 ব্যাখ্যা:** এই playbook servers এ Docker, dependencies ইত্যাদি install করবে

### ধাপ ৫: Application Deploy করুন

```bash
# Application deploy করুন
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml
```

**💡 ব্যাখ্যা:** এই playbook application code copy করবে এবং containers start করবে

### ধাপ ৬: Backup Setup করুন

```bash
# Automated backup setup করুন
ansible-playbook -i inventory/hosts.ini playbooks/backup.yml
```

### ধাপ ৭: Status Check করুন

```bash
# Servers এ application status check করুন
ansible all -i inventory/hosts.ini -m shell -a "docker ps"
```

### Complete Guide:

বিস্তারিত guide আছে: `ansible/README.md`

---

## Monitoring & Logging Setup

### 🎯 Monitoring Setup (Prometheus + Grafana)

### ধাপ ১: Monitoring Folder এ যান

```bash
cd /home/arif/DhakaCart-03/monitoring
```

### ধাপ ২: Monitoring Stack Start করুন

```bash
# Monitoring services start করুন
docker compose up -d
```

### ধাপ ৩: Access করুন

```
Grafana:    http://localhost:3001
Username:   admin
Password:   dhakacart123

Prometheus: http://localhost:9090
```

### ধাপ ৪: Dashboards Check করুন

1. Grafana login করুন
2. Dashboards menu এ যান
3. "DhakaCart" dashboards দেখুন

### 🎯 Logging Setup (Loki)

### ধাপ ১: Logging Folder এ যান

```bash
cd /home/arif/DhakaCart-03/logging
```

### ধাপ ২: Logging Stack Start করুন

```bash
# Logging services start করুন
docker compose up -d
```

### ধাপ ৩: Grafana এ Loki Add করুন

1. Grafana এ যান (http://localhost:3001)
2. Configuration → Data Sources
3. "Add data source" → "Loki" select করুন
4. URL: `http://loki:3100`
5. "Save & Test"

### ধাপ ৪: Logs Query করুন

1. Grafana → Explore
2. Data source: Loki select করুন
3. Query: `{service="backend"}`
4. Logs দেখুন

---

## Backup System Setup

### 🎯 Automated Backup Setup

### ধাপ ১: Backup Scripts Check করুন

```bash
cd /home/arif/DhakaCart-03/scripts/backup
ls -la
```

### ধাপ ২: Manual Backup Test করুন

```bash
# PostgreSQL backup
./backup-postgres.sh

# Redis backup
./backup-redis.sh

# Complete backup
./backup-all.sh
```

### ধাপ ৩: Backup Location Check করুন

```bash
# Backups কোথায় save হচ্ছে
ls -lh /backups/postgres/
ls -lh /backups/redis/
```

### ধাপ ৪: Automated Backup Setup করুন

```bash
# Cron job setup করুন (daily backup)
./backup-cron.sh
```

**💡 ব্যাখ্যা:** এই script daily automatic backup setup করবে

### ধাপ ৫: Restore Test করুন

```bash
cd ../restore

# Restore test করুন
./test-restore.sh
```

---

## Troubleshooting

### ❌ Problem 1: Docker Install হয়নি

**Solution:**
```bash
# Linux এ
sudo apt update
sudo apt install -y docker.io docker-compose

# Service start করুন
sudo systemctl start docker
sudo systemctl enable docker
```

### ❌ Problem 2: Port Already in Use

**Error:** `port 3000 is already in use`

**Solution:**
```bash
# কোন process port use করছে check করুন
sudo lsof -i :3000

# বা
sudo netstat -tulpn | grep 3000

# Process kill করুন
sudo kill -9 <PID>

# বা docker-compose.yml এ port change করুন
```

### ❌ Problem 3: Containers Start হচ্ছে না

**Solution:**
```bash
# Logs check করুন
docker compose logs

# Specific service logs
docker compose logs backend

# Containers restart করুন
docker compose restart

# সব delete করে fresh start
docker compose down -v
docker compose up -d
```

### ❌ Problem 4: Database Connection Failed

**Solution:**
```bash
# Database container check করুন
docker compose ps database

# Database logs check করুন
docker compose logs database

# Database restart করুন
docker compose restart database

# Wait করুন database ready হতে
sleep 10
docker compose restart backend
```

### ❌ Problem 5: Out of Memory

**Error:** `Cannot allocate memory`

**Solution:**
```bash
# Docker memory limit increase করুন (Docker Desktop settings)
# বা containers restart করুন
docker compose restart

# বা unused containers remove করুন
docker system prune -a
```

### ❌ Problem 6: Permission Denied

**Error:** `Permission denied`

**Solution:**
```bash
# Linux এ user কে docker group এ add করুন
sudo usermod -aG docker $USER

# Logout/login করুন
# বা
newgrp docker
```

### ❌ Problem 7: Images Download হচ্ছে না

**Solution:**
```bash
# Internet connection check করুন
ping google.com

# Docker daemon running আছে কিনা
sudo systemctl status docker

# Docker restart করুন
sudo systemctl restart docker
```

### ❌ Problem 8: Frontend Backend Connect করতে পারছে না

**Solution:**
```bash
# Network check করুন
docker network ls
docker network inspect dhakacart-network

# Backend health check করুন
curl http://localhost:5000/health

# Environment variables check করুন
docker compose exec backend env | grep API
```

---

## 📚 Additional Resources

### Documentation Files:

1. **Main README:** `README.md`
2. **Kubernetes Guide:** `k8s/DEPLOYMENT_GUIDE.md`
3. **Terraform Guide:** `terraform/README.md`
4. **Ansible Guide:** `ansible/README.md`
5. **Monitoring Guide:** `monitoring/README.md`
6. **Logging Guide:** `logging/README.md`
7. **Backup Guide:** `scripts/README.md`
8. **Security Guide:** `security/README.md`

### Quick Commands Reference:

```bash
# Application start
docker compose up -d

# Application stop
docker compose down

# Logs দেখুন
docker compose logs -f

# Status check
docker compose ps

# Restart specific service
docker compose restart backend

# Remove everything
docker compose down -v
```

---

## ✅ Deployment Checklist

### Before Deployment:
- [ ] Docker installed এবং running
- [ ] Project folder access করতে পারছি
- [ ] `.env` file তৈরি করেছি
- [ ] Ports available (3000, 5000, 5432, 6379)
- [ ] Enough disk space (20GB+)
- [ ] Enough RAM (8GB+)

### During Deployment:
- [ ] `docker compose up -d` run করেছি
- [ ] Containers running আছে (`docker compose ps`)
- [ ] No errors in logs (`docker compose logs`)
- [ ] Frontend accessible (http://localhost:3000)
- [ ] Backend accessible (http://localhost:5000/health)

### After Deployment:
- [ ] Application working properly
- [ ] Database connected
- [ ] Redis connected
- [ ] Monitoring setup (optional)
- [ ] Logging setup (optional)
- [ ] Backup configured (optional)

---

## 🎉 Success!

যদি সব steps follow করে application successfully deploy হয়ে থাকে, তাহলে:

**✅ Congratulations!** আপনার DhakaCart application এখন running আছে!

### Next Steps:

1. **Monitoring Setup করুন** (optional) - Real-time metrics দেখার জন্য
2. **Logging Setup করুন** (optional) - Logs analyze করার জন্য
3. **Backup Configure করুন** (recommended) - Data safety এর জন্য
4. **Security Scan করুন** (recommended) - Vulnerabilities check করার জন্য

---

## 📞 Help & Support

### যদি কোনো সমস্যা হয়:

1. **Logs check করুন:**
   ```bash
   docker compose logs
   ```

2. **Documentation পড়ুন:**
   - `README.md`
   - Component-specific README files

3. **Troubleshooting section দেখুন** (এই guide এর উপরে)

4. **Project Summary দেখুন:**
   ```bash
   cat docs/PROJECT_COMPLETION_SUMMARY.md
   ```

---

## 🎓 Final Notes

এই guide non-coder ব্যক্তিদের জন্য তৈরি করা হয়েছে। প্রতিটা command এর ব্যাখ্যা দেওয়া আছে যাতে আপনি বুঝতে পারেন কী হচ্ছে।

**মনে রাখবেন:**
- ধীরে ধীরে steps follow করুন
- Error হলে logs check করুন
- Documentation পড়ুন
- Practice করুন

**Best of luck with your deployment! 🚀**

---

**Created:** ২৩ নভেম্বর, ২০২৪  
**Version:** 1.0  
**For:** DhakaCart E-Commerce Platform  
**Target Audience:** Non-coder DevOps Engineers

