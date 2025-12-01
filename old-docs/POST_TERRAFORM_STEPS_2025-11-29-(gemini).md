ঠিক আছে, আমি বুঝতে পেরেছি। আপনি **Technical Implementation Details** এবং **Exact Commands** চাচ্ছেন। কোনো রূপক বা সহজ ব্যাখ্যা নয়, সরাসরি **Production Grade Installation Steps** নিচে দেওয়া হলো।

এই গাইডটি ধরে নিবে যে Terraform এর মাধ্যমে আপনার Infrastructure (EC2, VPC, LB) রেডি আছে।

-----

# 🛠️ Phase 2: Kubernetes Cluster Installation (Detailed)

এই ধাপগুলো **Master-1, Master-2, Worker-1, Worker-2, Worker-3** সব সার্ভারে রান করতে হবে।

### ধাপ ১: SSH Key সেটআপ (Bastion Host এ)

প্রথমে আপনার Local Machine থেকে Key টি Bastion এ এবং Bastion থেকে Master-1 এ নিতে হবে।

**Local Machine এ:**

```bash
# Key টি Bastion এ পাঠান
scp -i dhakacart-k8s-key.pem dhakacart-k8s-key.pem ubuntu@<BASTION_PUBLIC_IP>:/home/ubuntu/.ssh/id_rsa

# Bastion এ লগিন করুন
ssh -i dhakacart-k8s-key.pem ubuntu@<BASTION_PUBLIC_IP>
```

**Bastion Host এ:**

```bash
# Key এর পারমিশন ঠিক করুন (খুবই জরুরি)
chmod 400 ~/.ssh/id_rsa
```

-----

### ধাপ ২: সব নোড প্রস্তুত করা (Common Steps for ALL Nodes)

নিচের কমান্ডগুলো **প্রতিটি সার্ভারে (2 Masters + 3 Workers)** রান করতে হবে। বারবার টাইপ না করে একটি স্ক্রিপ্ট বানিয়ে রান করাই ভালো।

**1. Root User এ যান:**

```bash
sudo -i
```

**2. prerequisites.sh নামে একটি ফাইল বানান এবং রান করুন:**

```bash
cat <<EOF > prerequisites.sh
#!/bin/bash

# ১. সোয়াপ মেমরি ডিজেবল (K8s এর জন্য বাধ্যতামূলক)
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ২. মডিউল লোড করা
cat <<MODULES | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES

modprobe overlay
modprobe br_netfilter

# ৩. নেটওয়ার্ক কনফিগারেশন (Sysctl params)
cat <<SYSCTL | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL

sysctl --system

# ৪. কন্টেইনার রানটাইম (Containerd) ইন্সটল
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="\$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "\$(. /etc/os-release && echo "\$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

# ৫. Containerd কনফিগারেশন (SystemdCgroup এনাবল করা জরুরি)
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

# ৬. Kubernetes প্যাকেজ ইন্সটল (Kubeadm, Kubelet, Kubectl)
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

EOF

# স্ক্রিপ্ট রান করুন
chmod +x prerequisites.sh
./prerequisites.sh
```

-----

### ধাপ ৩: ক্লাস্টার ইনিশিয়ালাইজ (শুধুমাত্র Master-1 এ)

Bastion থেকে **Master-1** (Private IP: 10.0.10.100 উদাহরণস্বরূপ) এ SSH করুন।

```bash
# শুধুমাত্র Master-1 এ রান করবেন
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint "LOAD_BALANCER_DNS_OR_MASTER_IP:6443" --upload-certs

# sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint "dhakacart-k8s-alb-868841931.ap-southeast-1.elb.amazonaws.com:6443" --upload-certs

# sudo kubeadm init --pod-network-cidr=10.244.0.0/16 \
--control-plane-endpoint "dhakacart-k8s-alb-868841931.ap-southeast-1.elb.amazonaws.com:6443" \
--upload-certs \
--ignore-preflight-errors=NumCPU

# sudo kubeadm init --pod-network-cidr=10.244.0.0/16 \
--upload-certs \
--ignore-preflight-errors=NumCPU

# kubeadm join 10.0.10.113:6443 --token 9tfam1.v77gfr8gvit6pjfg \
        --discovery-token-ca-cert-hash sha256:9cc9806d6c7a5658c6104adafea438e9e594006236db049a576cfc00a680ed91
```

*(নোট: আপনার যদি লোড ব্যালেন্সার সেট করা না থাকে, `--control-plane-endpoint` ফ্ল্যাগটি বাদ দিন বা Master-1 এর প্রাইভেট আইপি দিন)*

**আউটপুট সংরক্ষণ করুন:**
কমান্ডটি সফল হলে শেষে `kubeadm join ...` দিয়ে একটি আউটপুট আসবে। এটি নোটপ্যাডে কপি করে রাখুন।

**Kubeconfig সেটআপ (Master-1 এ):**

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**নেটওয়ার্ক প্লাগিন (CNI) ইন্সটল (Flannel):**

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

-----

### ধাপ ৪: ওয়ার্কার নোড জয়েন করানো

আপনার Worker নোডটি ক্লাস্টারে যোগ করার জন্য প্রয়োজনীয় সমস্ত ধাপ নিচে দেওয়া হলো। এই প্রক্রিয়াটি Master নোড সেটআপের মতোই, তবে এখানে kubeadm init এর পরিবর্তে kubeadm join কমান্ড ব্যবহার করা হবে।

Worker নোডটি যোগ করার জন্য আপনার যে Join Command টি লাগবে, তা হলো:

Bash

sudo kubeadm join 10.0.10.113:6443 --token wy3vbu.wzwwr3uxtic46kmj \
     --discovery-token-ca-cert-hash sha256:bf5a5561d5d0096a221a4e8ab7a4d63d9ac42285fd7bb96c4b82ab7947fd631c
🛠️ পর্ব ১: Worker নোডে প্রী-রিকুইজিট সেটআপ
Worker নোড (যেমন Worker-1) এ SSH করে নিচের ধাপগুলো অনুসরণ করুন।

ধাপ ১: সিস্টেম আপডেট ও প্রয়োজনীয় টুলস ইনস্টল
Bash

# System update
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
ধাপ ২: Swap Disable ও Kernel মডিউল কনফিগার
Kubernetes সঠিকভাবে কাজ করার জন্য swap বন্ধ করতে হবে।

Bash

# Swap disable
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Kernel modules load
sudo modprobe overlay
sudo modprobe br_netfilter

# Kernel parameters & apply
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
ধাপ ৩: Containerd ইনস্টল এবং Cgroup Fix
Worker নোডে কন্টেইনার চালানোর জন্য containerd রানটাইম ইনস্টল করুন।

Bash

# Containerd install & Cgroup fix
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
# Cgroup fix: SystemdCgroup = true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
ধাপ ৪: Kubernetes টুলস ইনস্টল (v1.29)
Master নোডগুলোর সাথে একই সংস্করণ (v1.29) ইনস্টল করুন।

Bash

# Kubernetes tools install (v1.29 এর জন্য নতুন রিপোজিটরি)
sudo rm /etc/apt/sources.list.d/kubernetes.list 2>/dev/null
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
🚀 পর্ব ২: Worker নোড যোগ করা
ধাপ ৫: ক্লাস্টারে Worker নোড জয়েন করান
আপনার উপরে দেওয়া Worker Join Command টি এখন Worker নোডে রান করুন। এতে কোনো --control-plane বা --certificate-key ফ্ল্যাগ থাকবে না।

Bash

# Worker-1 এ রান করুন
sudo kubeadm join 10.0.10.113:6443 --token wy3vbu.wzwwr3uxtic46kmj \
     --discovery-token-ca-cert-hash sha256:bf5a5561d5d0096a221a4e8ab7a4d63d9ac42285fd7bb96c4b82ab7947fd631c
ধাপ ৬: স্থিতি যাচাই করুন
জয়েন সফল হলে, Master-1 এ ফিরে যান এবং দেখুন Worker নোডটি Ready দেখাচ্ছে কিনা।

Master-1 এ SSH করুন এবং চালান:

Bash

kubectl get nodes
আউটপুটে আপনার Master-1, Master-2 এবং নতুন Worker নোডটি দেখা যাবে।

NAME         STATUS   ROLES           AGE     VERSION
master-1     Ready    control-plane   ...     v1.29.15
master-2     Ready    control-plane   ...     v1.29.15
worker-1     Ready    <none>          ...     v1.29.15
এভাবে আপনি সফলভাবে আপনার Worker নোডটি ক্লাস্টারে যোগ করতে পারবেন।

-----

### ধাপ ৫: ভেরিফিকেশন

Master-1 এ ফিরে এসে চেক করুন:

```bash
kubectl get nodes
```

সব নোড `Ready` স্ট্যাটাসে আসলে Phase 2 সম্পন্ন।

-----

# 🚀 Phase 3: Application Deployment (Detailed)

এখন আমরা `kubectl` ব্যবহার করে অ্যাপ্লিকেশন ডেপ্লয় করব। আপনার Local Machine থেকে `kubectl` কাজ করার কথা যদি আপনি `~/.kube/config` ফাইলটি Master-1 থেকে আপনার লোকাল মেশিনে কপি করে আনেন।

**কমান্ডগুলো পর্যায়ক্রমে রান করুন:**

**১. নেমস্পেস তৈরি:**

```bash
kubectl create namespace dhakacart
```

**২. সিক্রেটস (Database Password):**

```bash
# ম্যানুয়ালি সিক্রেট তৈরি করুন (YAML ফাইল না থাকলে)
kubectl create secret generic db-credentials \
  --from-literal=username=postgres \
  --from-literal=password=mysecretpassword123 \
  -n dhakacart
```

**৩. কনফিগারেশন ম্যাপ (ConfigMap):**

```bash
kubectl apply -f k8s/configmaps/app-config.yaml -n dhakacart
```

**৪. পারসিস্টেন্ট ভলিউম (PVC - ডাটা সেভ রাখার জন্য):**

```bash
kubectl apply -f k8s/volumes/pvc.yaml -n dhakacart
```

**৫. ডাটাবেস (PostgreSQL) ডেপ্লয়:**

```bash
kubectl apply -f k8s/deployments/postgres-deployment.yaml -n dhakacart
kubectl apply -f k8s/services/postgres-service.yaml -n dhakacart
```

**৬. রেডিস (Redis) ডেপ্লয়:**

```bash
kubectl apply -f k8s/deployments/redis-deployment.yaml -n dhakacart
kubectl apply -f k8s/services/redis-service.yaml -n dhakacart
```

**৭. ব্যাকএন্ড (Backend API) ডেপ্লয়:**

```bash
kubectl apply -f k8s/deployments/backend-deployment.yaml -n dhakacart
kubectl apply -f k8s/services/backend-service.yaml -n dhakacart
```

**৮. ফ্রন্টএন্ড (Frontend) ডেপ্লয়:**

```bash
kubectl apply -f k8s/deployments/frontend-deployment.yaml -n dhakacart
kubectl apply -f k8s/services/frontend-service.yaml -n dhakacart
```

**Check Status:**

```bash
kubectl get pods -n dhakacart -w
```

সব Pod `Running` এবং `1/1` হওয়া পর্যন্ত অপেক্ষা করুন।

-----

# 🌐 Phase 4: Configure Public Access (Ingress)

AWS Load Balancer এর সাথে Kubernetes এর সংযোগ করার জন্য **Ingress Controller** লাগবে।

### ১. NGINX Ingress Controller ইন্সটল

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml
```

এটি AWS এ একটি **Classic Load Balancer (CLB)** বা **Network Load Balancer (NLB)** তৈরি করবে।

### ২. Ingress Resource অ্যাপ্লাই

আপনার `k8s/ingress/ingress.yaml` ফাইলে নিচের কনফিগারেশন থাকা জরুরি:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dhakacart-ingress
  namespace: dhakacart
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dhakacart-frontend-service # আপনার ফ্রন্টএন্ড সার্ভিস নাম
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: dhakacart-backend-service # আপনার ব্যাকএন্ড সার্ভিস নাম
            port:
              number: 5000
```

**কমান্ড:**

```bash
kubectl apply -f k8s/ingress/ingress.yaml -n dhakacart
```

### ৩. ফাইনাল অ্যাক্সেস ইউআরএল

লোড ব্যালেন্সার এর অ্যাড্রেস পেতে:

```bash
kubectl get svc -n ingress-nginx
```

`EXTERNAL-IP` এর নিচে একটি বিশাল `xxxx.us-east-1.elb.amazonaws.com` লিঙ্ক পাবেন। এটিই আপনার সাইটের অ্যাড্রেস।

-----

এই ধাপগুলো হুবহু ফলো করলে আপনার ক্লাস্টার এবং অ্যাপ রান করবে। কোনো নির্দিষ্ট কমান্ডে এরর আসলে জানাবেন, আমি স্পেসিফিক ফিক্স দিব।