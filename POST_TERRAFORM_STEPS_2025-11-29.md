# 🚀 Terraform Deployment এর পর - ধাপে ধাপে Guide

**তারিখ:** ২৯ নভেম্বর, ২০২৫   
**প্রজেক্ট:** DhakaCart E-Commerce Platform  
**লক্ষ্য:** Terraform deployment এর পর কী করতে হবে - সহজ ভাষায়

---

## 📋 Overview

Terraform দিয়ে AWS infrastructure deploy করার পর, আপনার কাছে **শুধু servers আছে** কিন্তু:
- ❌ Kubernetes install হয়নি
- ❌ DhakaCart application deploy হয়নি
- ❌ Public access configure হয়নি

**এই guide এ:** Terraform এর পরের সব steps সহজ ভাষায় বলা হয়েছে।

---

## 🎯 সহজ ভাষায় বুঝি:

### এখন আপনার কাছে যা আছে (After Terraform):

```
AWS এ:
├── 🖥️ 5টি Servers (EC2 instances)
│   ├── 1টি Bastion (SSH gateway)
│   ├── 2টি Master nodes (Kubernetes control)
│   └── 3টি Worker nodes (Application চালাবে)
│
├── 🌐 1টি Load Balancer (Public access এর জন্য)
│
└── 🔐 Security Groups, VPC, Subnets (Network setup)
```

**কিন্তু:**
- Servers এ **Kubernetes install হয়নি**
- **DhakaCart application deploy হয়নি**
- **Public URL কাজ করছে না**

### যা করতে হবে:

```
Phase 2: Kubernetes Install
  └── Servers এ Kubernetes software install

Phase 3: Application Deploy  
  └── DhakaCart application Kubernetes এ deploy

Phase 4: Public Access
  └── Load Balancer configure করে website access
```

---

## 📊 4টি Phase - সম্পূর্ণ Process

### ✅ Phase 1: Infrastructure (Terraform) - COMPLETED

**আপনি যা করেছিলেন:**
```bash
cd terraform/simple-k8s
terraform apply
```

**ফলাফল:**
- ✅ 5টি servers create হয়েছে
- ✅ Network setup হয়েছে
- ✅ Load Balancer ready হয়েছে
- ✅ SSH key তৈরি হয়েছে
- ✅ **Output data automatically saved** to `aws_instances_output.txt`

**📄 Output File:**
Terraform apply এর পর সব output data automatically `terraform/simple-k8s/aws_instances_output.txt` file এ save হয়ে যাবে। এই file এ আপনি পাবেন:
- Bastion host এর Public IP এবং SSH command
- Master nodes এর Private IPs এবং SSH commands
- Worker nodes এর Private IPs এবং SSH commands
- Load Balancer DNS এবং Public URL
- VPC এবং Network information
- সব SSH commands ready-made format এ

**Output File Check করুন:**
```bash
# Output file দেখুন
cat terraform/simple-k8s/aws_instances_output.txt

# বা specific information খুঁজুন
grep "Public IP" terraform/simple-k8s/aws_instances_output.txt
grep "Private IP" terraform/simple-k8s/aws_instances_output.txt
```

**💡 Tip:** এই file থেকে সব IP addresses এবং commands copy করে ব্যবহার করতে পারবেন!

**Time:** 10-15 মিনিট

---

### ⏳ Phase 2: Kubernetes Installation - NEXT STEP

**কী করবেন:** সব servers এ Kubernetes software install করবেন

**কেন দরকার:**
- Kubernetes = Application run করার platform
- এটা ছাড়া DhakaCart deploy করা যাবে না

#### ধাপ ২.১: Bastion Host এ Connect করুন

**কেন Bastion:**
- Bastion = Gateway/doorway
- Private servers এ direct access নেই
- Bastion দিয়ে private servers এ যেতে হবে

**📄 প্রথমে Output File Check করুন:**
```bash
# Output file থেকে Bastion IP এবং SSH command দেখুন
cat terraform/simple-k8s/aws_instances_output.txt | grep -A 5 "BASTION HOST"
```

**Command:**
```bash
# আপনার local computer থেকে
cd /home/arif/DhakaCart-03/terraform/simple-k8s

# Output file থেকে Bastion IP নিন (বা direct command use করুন)
# Example (আপনার actual IP output file এ দেখুন):
ssh -i dhakacart-k8s-key.pem ubuntu@<BASTION_PUBLIC_IP>

# বা output file থেকে ready-made command copy করুন
# aws_instances_output.txt file এ "SSH Command:" line এ exact command আছে
```

**💡 সহজ উপায়:**
Output file (`aws_instances_output.txt`) open করুন এবং "BASTION HOST" section থেকে SSH command copy করে run করুন!

**✅ Success হলে:** Terminal এ `ubuntu@bastion:~$` দেখাবে

**💡 ব্যাখ্যা:**
- `ssh` = Secure Shell (remote computer access)
- `-i dhakacart-k8s-key.pem` = SSH key file
- Bastion IP = `aws_instances_output.txt` file এ দেখুন

#### ধাপ ২.২: SSH Key Copy করুন

**কেন দরকার:**
- Bastion থেকে private servers এ SSH করতে key লাগবে
- Key bastion এ copy করতে হবে

**📄 Output File থেকে Bastion IP নিন:**
```bash
# Output file থেকে Bastion IP check করুন
grep "Public IP:" terraform/simple-k8s/aws_instances_output.txt
```

**Command (Bastion এ থাকার সময়):**
```bash
# Bastion এ, exit করুন (local computer এ ফিরে আসুন)
exit

# Local computer থেকে key copy করুন
# <BASTION_IP> এর জায়গায় output file থেকে IP use করুন
scp -i terraform/simple-k8s/dhakacart-k8s-key.pem \
    terraform/simple-k8s/dhakacart-k8s-key.pem \
    ubuntu@<BASTION_IP>:~/.ssh/dhakacart-k8s-key.pem

# Key permissions set করুন
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP> \
    "chmod 400 ~/.ssh/dhakacart-k8s-key.pem"
```

**💡 সহজ উপায়:**
Output file এ "NEXT STEPS" section এ step 2 এ exact command আছে - সেটা copy করে use করুন!

**💡 ব্যাখ্যা:**
- `scp` = Secure Copy (file copy করার command)
- Key bastion এ copy হচ্ছে যাতে bastion থেকে other servers এ যাওয়া যায়

#### ধাপ ২.৩: Connectivity Test করুন

**কেন test:**
- সব servers reachable আছে কিনা check করতে হবে
- Ping test = Network connectivity check

**📄 Output File থেকে IPs নিন:**
```bash
# Output file থেকে সব Private IPs দেখুন
grep "Private IP:" terraform/simple-k8s/aws_instances_output.txt
```

**Command (Bastion এ থেকে):**
```bash
# Bastion এ connect করুন আবার
# Output file থেকে Bastion IP use করুন
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP>

# Output file থেকে Private IPs নিয়ে ping test করুন
# Master nodes
ping -c 2 <MASTER_1_PRIVATE_IP>
ping -c 2 <MASTER_2_PRIVATE_IP>

# Worker nodes
ping -c 2 <WORKER_1_PRIVATE_IP>
ping -c 2 <WORKER_2_PRIVATE_IP>
ping -c 2 <WORKER_3_PRIVATE_IP>
```

**💡 সহজ উপায়:**
Output file এ "Master Private IPs:" এবং "Worker Private IPs:" line এ comma-separated IPs আছে - সেগুলো use করুন!

**✅ Expected Output:**
```
PING 10.0.10.xxx (10.0.10.xxx) 56(84) bytes of data.
64 bytes from 10.0.10.xxx: icmp_seq=1 ttl=64 time=0.2 ms
64 bytes from 10.0.10.xxx: icmp_seq=2 ttl=64 time=0.3 ms
```

**যদি ping কাজ করে, তাহলে network ঠিক আছে! ✅**

#### ধাপ ২.৪: Master-1 এ Kubernetes Install করুন

**কেন Master-1 প্রথমে:**
- Master-1 = Cluster initialize করবে
- বাকি nodes Master-1 এর সাথে join করবে

**📄 Output File থেকে Master-1 IP নিন:**
```bash
# Output file থেকে Master-1 Private IP দেখুন
grep -A 4 "Master-1:" terraform/simple-k8s/aws_instances_output.txt
```

**Commands:**
```bash
# Bastion থেকে Master-1 এ SSH করুন
# Output file থেকে Master-1 Private IP use করুন
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER_1_PRIVATE_IP>

# বা output file এ "Master-1:" section এ ready-made SSH command আছে
# এখন আপনি Master-1 এ আছেন
```

**Kubernetes Install Script:**

Master-1 এ এই commands run করুন:

```bash
# Step 1: System update
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Step 2: Swap disable (Kubernetes এর জন্য প্রয়োজনীয়)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Step 3: Kernel modules load
sudo modprobe overlay
sudo modprobe br_netfilter

# Step 4: Kernel parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Step 5: Containerd install (Container runtime)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Step 6: Kubernetes tools install
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=1.28.0-00 kubeadm=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubeadm kubectl

# Step 7: Kubernetes cluster initialize
# ⚠️ Important: Use Master-1's private IP, NOT ALB DNS
# ALB doesn't support TCP on port 6443 (only HTTP/HTTPS)
# Get Master-1 private IP from output file
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Alternative: If you need HA setup later, use Master-1 private IP as control-plane-endpoint
# sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint "<MASTER_1_PRIVATE_IP>:6443"

# Step 8: kubeconfig setup (Important!)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Step 9: CNI install (Network plugin - Flannel)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Step 10: Wait for cluster ready
sleep 30
kubectl get nodes
```

**⏱️ Time:** ৫-১০ মিনিট

**✅ Success হলে:**
```
NAME       STATUS   ROLES           AGE   VERSION
master-1   Ready    control-plane   1m    v1.28.0
```

**💡 Important:** 
- Initialize এর শেষে একটা **join command** দেখাবে
- সেই command save করুন (আগে পরে লাগবে)
- ⚠️ **ALB DNS ব্যবহার করবেন না** `kubeadm init` এ - ALB TCP support করে না, শুধু HTTP/HTTPS
- Master-1 এর private IP use করুন (output file এ আছে)

#### ধাপ ২.৫: Master-2 Join করুন

**কেন:**
- High Availability এর জন্য 2টি master প্রয়োজন

**📄 Output File থেকে Master-2 IP নিন:**
```bash
# Output file থেকে Master-2 Private IP দেখুন
grep -A 4 "Master-2:" terraform/simple-k8s/aws_instances_output.txt
```

**Commands:**
```bash
# Master-1 থেকে exit করুন, Bastion এ ফিরে আসুন
exit

# Bastion থেকে Master-2 এ SSH করুন
# Output file থেকে Master-2 Private IP use করুন
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER_2_PRIVATE_IP>

# Master-2 এ Kubernetes install করুন (same commands as Master-1, Step 1-6)
# তারপর Master-1 এ পাওয়া join command run করুন
```

**💡 ব্যাখ্যা:**
- Master-2 Master-1 এর cluster এ join করবে
- Join command Master-1 এ `kubeadm init` এর পরে দেখাবে

#### ধাপ ২.৬: Worker Nodes Join করুন

**কেন:**
- Workers = Application চালাবে
- 3টি worker nodes আছে

**📄 Output File থেকে Worker IPs নিন:**
```bash
# Output file থেকে সব Worker Private IPs দেখুন
grep -A 4 "Worker-" terraform/simple-k8s/aws_instances_output.txt
```

**Process (প্রতিটি Worker এ):**

```bash
# Bastion থেকে Worker-1 এ SSH
# Output file থেকে Worker-1 Private IP use করুন
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<WORKER_1_PRIVATE_IP>

# Kubernetes install (Step 1-6 same as Master-1)
# তারপর Worker join command run করুন (Master-1 থেকে পাওয়া)

# Worker-2 এবং Worker-3 এ same process
# Output file থেকে respective IPs use করুন
```

**⏱️ Time:** Worker প্রতি ৫-৭ মিনিট

**✅ Final Check:**
```bash
# Master-1 এ থেকে
kubectl get nodes
```

**Expected Output:**
```
NAME       STATUS   ROLES           AGE   VERSION
master-1   Ready    control-plane   5m    v1.28.0
master-2   Ready    control-plane   3m    v1.28.0
worker-1   Ready    <none>          2m    v1.28.0
worker-2   Ready    <none>          2m    v1.28.0
worker-3   Ready    <none>          2m    v1.28.0
```

**যদি সব "Ready" দেখায়, তাহলে Kubernetes cluster ready! ✅**

---

### ⏳ Phase 3: DhakaCart Application Deployment

**কী করবেন:** DhakaCart application Kubernetes cluster এ deploy করবেন

**কেন দরকার:**
- Application deploy না করলে website কাজ করবে না
- Application = Frontend, Backend, Database, Redis

#### ধাপ ৩.১: kubeconfig Local Machine এ Copy করুন

**কেন:**
- Local machine থেকে Kubernetes cluster access করার জন্য

**📄 Output File থেকে Bastion IP নিন:**
```bash
# Output file থেকে Bastion Public IP দেখুন
grep "Public IP:" terraform/simple-k8s/aws_instances_output.txt
```

**Commands:**
```bash
# Bastion এ থেকে
exit

# Local machine থেকে bastion এ kubeconfig copy করুন
# Output file থেকে Bastion IP use করুন
scp -i terraform/simple-k8s/dhakacart-k8s-key.pem \
    ubuntu@<BASTION_IP>:~/.kube/config \
    ~/.kube/config

# Permissions set করুন
chmod 600 ~/.kube/config

# Test করুন
kubectl get nodes
```

**✅ Success হলে:** Local machine থেকে cluster দেখাবে

#### ধাপ ৩.২: Application Files Check করুন

**Files Location:**
```
DhakaCart-03/
└── k8s/
    ├── namespace.yaml
    ├── secrets/
    ├── configmaps/
    ├── volumes/
    ├── deployments/
    ├── services/
    └── ingress/
```

**Commands:**
```bash
# Project folder এ যান
cd /home/arif/DhakaCart-03

# Files check করুন
ls -la k8s/
ls -la k8s/deployments/
ls -la k8s/services/
```

#### ধাপ ৩.৩: Namespace Create করুন

**কেন:**
- Namespace = Separate area/cluster ভিতর
- DhakaCart application আলাদা namespace এ থাকবে

**Command:**
```bash
kubectl apply -f k8s/namespace.yaml
```

**✅ Verify:**
```bash
kubectl get namespace dhakacart
```

#### ধাপ ৩.৪: Secrets Create করুন

**কেন:**
- Database password এবং sensitive data store করতে হবে
- Kubernetes secrets = Password store করার safe way

**Command:**
```bash
kubectl apply -f k8s/secrets/db-secrets.yaml
```

**✅ Verify:**
```bash
kubectl get secrets -n dhakacart
```

**💡 Note:** Password change করতে পারেন (production এ)

#### ধাপ ৩.৫: ConfigMaps Create করুন

**কেন:**
- Application configuration store করতে হবে

**Command:**
```bash
kubectl apply -f k8s/configmaps/
```

#### ধাপ ৩.৬: Volumes Create করুন

**কেন:**
- Database data permanently store করার জন্য
- Volumes = Permanent storage

**Command:**
```bash
kubectl apply -f k8s/volumes/pvc.yaml
```

**✅ Verify:**
```bash
kubectl get pvc -n dhakacart
```

#### ধাপ ৩.৭: Database Deploy করুন

**কেন:**
- Database = সব data store করবে
- প্রথমে database deploy করতে হবে (Backend এ লাগবে)

**Command:**
```bash
kubectl apply -f k8s/deployments/postgres-deployment.yaml
```

**⏱️ Wait:** ১-২ মিনিট

**✅ Verify:**
```bash
kubectl get pods -n dhakacart -l app=dhakacart-db

# Expected:
# NAME                              READY   STATUS    RESTARTS   AGE
# dhakacart-db-xxxxxxxxxx-xxxxx     1/1     Running   0          1m
```

**💡 ব্যাখ্যা:**
- `1/1 Ready` = Pod running এবং ready
- `Running` = Container successfully started

#### ধাপ ৩.৮: Redis Deploy করুন

**কেন:**
- Redis = Cache/performance boost করার জন্য

**Command:**
```bash
kubectl apply -f k8s/deployments/redis-deployment.yaml
```

**✅ Verify:**
```bash
kubectl get pods -n dhakacart -l app=dhakacart-redis
```

#### ধাপ ৩.৯: Backend Deploy করুন

**কেন:**
- Backend = API server
- Database এবং Redis এর পরে deploy করতে হবে

**Command:**
```bash
kubectl apply -f k8s/deployments/backend-deployment.yaml
```

**⏱️ Wait:** ১-২ মিনিট

**✅ Verify:**
```bash
kubectl get pods -n dhakacart -l app=dhakacart-backend
```

#### ধাপ ৩.১০: Frontend Deploy করুন

**কেন:**
- Frontend = Website/User interface
- সবচেয়ে শেষে deploy করতে হবে

**Command:**
```bash
kubectl apply -f k8s/deployments/frontend-deployment.yaml
```

**✅ Verify:**
```bash
kubectl get pods -n dhakacart -l app=dhakacart-frontend
```

#### ধাপ ৩.১১: Services Create করুন

**কেন:**
- Services = Pods এর সাথে connect করার network endpoint
- Database, Backend, Frontend এর জন্য services লাগবে

**Command:**
```bash
kubectl apply -f k8s/services/services.yaml
```

**✅ Verify:**
```bash
kubectl get svc -n dhakacart
```

**Expected Output:**
```
NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
dhakacart-db-service        ClusterIP   10.96.x.x       <none>        5432/TCP
dhakacart-redis-service     ClusterIP   10.96.x.x       <none>        6379/TCP
dhakacart-backend-service   ClusterIP   10.96.x.x       <none>        5000/TCP
dhakacart-frontend-service  NodePort    10.96.x.x       <none>        80:30080/TCP
```

**💡 ব্যাখ্যা:**
- `ClusterIP` = Internal access only
- `NodePort` = External access (30080 port)

#### ধাপ ৩.১২: সব Pods Check করুন

**Command:**
```bash
kubectl get pods -n dhakacart
```

**✅ Expected (সব Running):**
```
NAME                                 READY   STATUS    RESTARTS   AGE
dhakacart-db-xxxxx                   1/1     Running   0          5m
dhakacart-redis-xxxxx                1/1     Running   0          4m
dhakacart-backend-xxxxx              1/1     Running   0          3m
dhakacart-frontend-xxxxx             1/1     Running   0          2m
```

**যদি সব "Running" এবং "1/1 Ready" দেখায়, তাহলে Application deployed! ✅**

---

### ⏳ Phase 4: Public Access Configuration

**কী করবেন:** Load Balancer configure করবেন যাতে Internet থেকে website access করা যায়

#### ধাপ ৪.১: Ingress Controller Install করুন

**কেন:**
- Ingress Controller = Load Balancer থেকে Pods এ traffic route করবে
- NGINX Ingress Controller = Popular choice

**Command:**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml
```

**⏱️ Wait:** ২-৩ মিনিট

**✅ Verify:**
```bash
kubectl get pods -n ingress-nginx
```

#### ধাপ ৪.২: Ingress Resource Create করুন

**কেন:**
- Ingress = Traffic routing rules
- Load Balancer থেকে Frontend pods এ traffic forward করবে

**Command:**
```bash
kubectl apply -f k8s/ingress/
```

**✅ Verify:**
```bash
kubectl get ingress -n dhakacart
```

#### ধাপ ৪.৩: Load Balancer DNS Get করুন

**📄 Output File থেকে DNS নিন (সবচেয়ে সহজ!):**
```bash
# Output file থেকে Load Balancer DNS দেখুন
grep "DNS Name:" terraform/simple-k8s/aws_instances_output.txt
grep "Public URL:" terraform/simple-k8s/aws_instances_output.txt
```

**Command (Alternative methods):**
```bash
# Method 1: Output file থেকে (Recommended)
cat terraform/simple-k8s/aws_instances_output.txt | grep "Public URL:"

# Method 2: Ingress Controller এর Load Balancer DNS
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Method 3: Terraform output থেকে
cd terraform/simple-k8s
terraform output load_balancer_url
```

**💡 সহজ উপায়:**
Output file (`aws_instances_output.txt`) open করুন এবং "LOAD BALANCER" section এ "Public URL:" line এ exact URL আছে - সেটা copy করে browser এ open করুন!

#### ধাপ ৪.৪: Website Test করুন

**📄 Output File থেকে URL নিন:**
```bash
# Output file থেকে Public URL copy করুন
grep "Public URL:" terraform/simple-k8s/aws_instances_output.txt
```

**Browser এ open করুন:**
Output file (`aws_instances_output.txt`) এ "LOAD BALANCER" section এ "Public URL:" line এ যে URL আছে, সেটা browser এ open করুন।

**💡 সহজ উপায়:**
Output file open করুন → "Public URL:" line copy করুন → Browser এ paste করুন!

**✅ Success হলে:** DhakaCart website দেখাবে! 🎉

---

## 📝 Complete Command Summary

### Phase 2: Kubernetes Installation

**📄 প্রথমে Output File Check করুন:**
```bash
# সব IPs এবং commands output file এ আছে
cat terraform/simple-k8s/aws_instances_output.txt
```

```bash
# 1. Bastion এ connect
# Output file থেকে Bastion IP এবং SSH command নিন
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP>

# 2. Master-1 এ SSH
# Output file থেকে Master-1 Private IP use করুন
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER_1_PRIVATE_IP>

# 3. Master-1 এ Kubernetes install এবং init
# (Commands উপরে দেওয়া আছে)

# 4. Master-2 এবং Workers এ join
# Output file থেকে respective IPs use করুন
# (Join commands Master-1 থেকে পাওয়া)
```

### Phase 3: Application Deployment

```bash
# Local machine থেকে
cd /home/arif/DhakaCart-03

# সব একসাথে deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/volumes/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
```

### Phase 4: Public Access

```bash
# Ingress Controller install
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Ingress create
kubectl apply -f k8s/ingress/
```

---

## 🎯 Simple Explanation

### এখন কী হয়েছে (After Terraform):

```
AWS:
├── Servers আছে ✅
├── Network আছে ✅
└── Load Balancer আছে ✅

কিন্তু:
├── Servers এ software নেই ❌
├── Application deploy হয়নি ❌
└── Website কাজ করছে না ❌
```

### যা করতে হবে:

**Step 1:** Servers এ Kubernetes install করুন
- কেন? Application run করার platform লাগবে

**Step 2:** DhakaCart application deploy করুন
- কেন? Website কাজ করবে

**Step 3:** Public access configure করুন
- কেন? Internet থেকে access করতে হবে

---

## 📊 Timeline

| Phase | What | Time | Status |
|-------|------|------|--------|
| Phase 1 | Terraform Infrastructure | 10-15 min | ✅ Done |
| Phase 2 | Kubernetes Installation | 30-45 min | ⏳ Next |
| Phase 3 | Application Deployment | 10-15 min | ⏳ After Phase 2 |
| Phase 4 | Public Access | 5-10 min | ⏳ After Phase 3 |

**Total Time:** ~১-১.৫ ঘন্টা

---

## 🔒 Security Groups Configuration

### Required Ports for Kubernetes

Terraform automatically configures security groups, but here's what should be open:

**Master/Worker Nodes Security Group (`k8s-nodes-sg`):**
- **Port 22 (SSH):** From Bastion security group
- **Port 6443 (Kubernetes API Server):** From ALB security group
- **Port 10250 (Kubelet API):** From k8s nodes (self)
- **Port 30000-32767 (NodePort):** From ALB security group
- **All ports (0-65535):** Between k8s nodes (self) - for Kubernetes internal communication

**ALB Security Group (`alb-sg`):**
- **Port 80 (HTTP):** From anywhere (0.0.0.0/0)
- **Port 443 (HTTPS):** From anywhere (0.0.0.0/0)
- **Outbound:** All traffic allowed

**Bastion Security Group (`bastion-sg`):**
- **Port 22 (SSH):** From anywhere (0.0.0.0/0)
- **Outbound:** All traffic allowed

**✅ Verification:**
```bash
# AWS Console এ check করুন:
# EC2 → Security Groups → k8s-nodes-sg
# Inbound rules এ দেখুন:
# - Port 6443 from alb-sg
# - Port 10250 from self
# - Port 22 from bastion-sg
```

---

## 🔍 Troubleshooting

### Problem: SSH Connection Failed

**Solution:**
```bash
# Key permissions check
chmod 400 terraform/simple-k8s/dhakacart-k8s-key.pem

# IP check
ping 47.128.147.39
```

### Problem: Kubernetes Install Failed / kubeadm init Timeout

**Error Message:**
```
timed out waiting for the condition
error execution phase wait-control-plane: couldn't initialize a Kubernetes cluster
```

**সমাধান (Step by Step):**

**1. Security Groups Check করুন:**
Terraform automatically security groups configure করে, কিন্তু verify করুন:
```bash
# AWS Console এ যান → EC2 → Security Groups
# Check করুন যে k8s-nodes security group এ আছে:
# - Port 6443 from ALB security group
# - Port 10250 from k8s nodes (self)
# - Port 22 from bastion
```

**2. Kubelet Status Check করুন:**
```bash
# Master-1 এ থেকে
sudo systemctl status kubelet

# যদি stopped থাকে, start করুন:
sudo systemctl start kubelet
sudo systemctl enable kubelet
```

**3. Containerd Status Check করুন:**
```bash
# Containerd running আছে কিনা check করুন
sudo systemctl status containerd

# যদি stopped থাকে:
sudo systemctl start containerd
sudo systemctl enable containerd
```

**4. Kubelet Logs Check করুন:**
```bash
# Detailed logs দেখুন
sudo journalctl -xeu kubelet --no-pager | tail -50

# Real-time logs
sudo journalctl -xeu kubelet -f
```

**5. Container Runtime Check করুন:**
```bash
# Running containers check করুন
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a

# Kubernetes containers check করুন
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a | grep kube | grep -v pause

# যদি কোনো container failed থাকে, logs দেখুন:
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs <CONTAINER_ID>
```

**6. Cgroup Issues Check করুন:**
```bash
# Cgroup v2 check করুন
mount | grep cgroup

# যদি cgroup v2 থাকে, disable করুন (temporary):
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"/' /etc/default/grub
sudo update-grub
sudo reboot
```

**7. Swap Check করুন:**
```bash
# Swap disable আছে কিনা check করুন
free -h
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

**8. Network Configuration Check করুন:**
```bash
# Kernel parameters check করুন
cat /etc/sysctl.d/k8s.conf

# যদি নেই, create করুন:
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

**9. Reset এবং Retry করুন:**
```bash
# যদি সব check করার পরেও কাজ না করে, reset করুন:
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/etcd
sudo rm -rf /etc/kubernetes

# তারপর আবার init করুন (ALB DNS ব্যবহার করবেন না):
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

**10. ALB DNS ব্যবহার করবেন না:**
⚠️ **Important:** `kubeadm init` এ ALB DNS ব্যবহার করবেন না কারণ:
- ALB (Application Load Balancer) শুধু HTTP/HTTPS support করে
- Kubernetes API Server (port 6443) TCP protocol ব্যবহার করে
- ALB TCP traffic handle করতে পারে না

**সঠিক Command:**
```bash
# ❌ Wrong (ALB DNS ব্যবহার করবেন না):
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint "dhakacart-k8s-alb-xxx.elb.amazonaws.com:6443"

# ✅ Correct (Private IP ব্যবহার করুন):
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# বা HA setup এর জন্য Master-1 private IP:
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint "<MASTER_1_PRIVATE_IP>:6443"
```

### Problem: Pods Not Starting

**Solution:**
```bash
# Pod logs
kubectl logs <pod-name> -n dhakacart

# Pod describe
kubectl describe pod <pod-name> -n dhakacart
```

### Problem: Website Not Loading

**Solution:**
```bash
# Services check
kubectl get svc -n dhakacart

# Ingress check
kubectl get ingress -n dhakacart

# Load Balancer check
kubectl get svc -n ingress-nginx
```

---

## ✅ Final Checklist

### After All Steps:

- [ ] All nodes Ready (`kubectl get nodes`)
- [ ] All pods Running (`kubectl get pods -n dhakacart`)
- [ ] Services created (`kubectl get svc -n dhakacart`)
- [ ] Ingress configured (`kubectl get ingress -n dhakacart`)
- [ ] Website accessible (Browser test)
- [ ] Database working (Check logs)
- [ ] Backend API working (Test endpoint)

---

## 🎉 Success!

যদি সব steps complete হয়ে থাকে:

1. ✅ Infrastructure ready (Terraform)
2. ✅ Kubernetes cluster ready
3. ✅ DhakaCart application deployed
4. ✅ Public access working

**আপনার DhakaCart website এখন Internet থেকে access করা যাবে! 🚀**

---

## 📄 Output File Reference

### `terraform/simple-k8s/aws_instances_output.txt`

Terraform apply এর পর এই file automatically create হবে এবং সব important information store করবে:

**এই file এ যা পাবেন:**
- ✅ Bastion host এর Public IP এবং SSH command
- ✅ Master nodes এর Private IPs, Instance IDs, SSH commands
- ✅ Worker nodes এর Private IPs, Instance IDs, SSH commands
- ✅ Load Balancer DNS name এবং Public URL
- ✅ VPC এবং Network information
- ✅ SSH key path এবং key name
- ✅ Cluster information (name, region, counts)
- ✅ Ready-made SSH commands সব steps এর জন্য

**কীভাবে use করবেন:**
```bash
# সম্পূর্ণ file দেখুন
cat terraform/simple-k8s/aws_instances_output.txt

# Specific information খুঁজুন
grep "Public IP" terraform/simple-k8s/aws_instances_output.txt
grep "Private IP" terraform/simple-k8s/aws_instances_output.txt
grep "Public URL" terraform/simple-k8s/aws_instances_output.txt

# Copy-paste ready commands
# File এ "SSH Command:" এবং "NEXT STEPS" section এ সব commands ready আছে
```

**💡 Tip:** এই file থেকে সব IPs এবং commands copy করে directly use করতে পারবেন - manual typing এর দরকার নেই!

---

## 📚 Related Documentation

- **Architecture:** `DEPLOYMENT_ARCHITECTURE(29-11-25).md`
- **Kubernetes Guide:** `k8s/DEPLOYMENT_GUIDE.md`
- **Manual Steps:** `terraform/k8s-ha-cluster/MANUAL_STEPS_AWS_DEPLOYMENT_2024-11-24.md`
- **Output File:** `terraform/simple-k8s/aws_instances_output.txt` (Auto-generated)

---

**Created:** ২৪ নভেম্বর, ২০২৪  
**Last Updated:** ২৯ নভেম্বর, ২০২৫  
**Status:** Complete Guide ✅

---

**Remember:** 
- ধীরে ধীরে steps follow করুন
- Error হলে logs check করুন
- সব commands copy-paste করে run করুন

**Good Luck! আপনি পারবেন! 💪**

