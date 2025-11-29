# 🛠️ Master-1 (Primary Control Plane) — Full Detailed Configuration

এই ডকুমেন্টে **Master-1** নোডে Kubernetes Control Plane সেটআপ করার সম্পূর্ণ স্টেপ-by-স্টেপ গাইড আছে।
Ubuntu 22.04 / 20.04–এর জন্য প্রস্তুত করা।

---

## 🔶 ১. সিস্টেম প্রি-রিকুইজিটস

Master নোডকে প্রস্তুত করতে প্রথমে সিস্টেম আপডেট, Kernel modules, Sysctl tuning এবং Swap disable করতে হবে।

```bash
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

### 🔸 Swap Disable (Kubernetes hard requirement)

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 🔸 Kernel Modules Enable

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

### 🔸 Sysctl Parameters

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

---

## 🔶 ২. Container Runtime (containerd) ইনস্টল

### 🔸 Docker Repo যোগ করা

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
```

### 🔸 Install containerd

```bash
sudo apt-get install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
```

### 🔸 Systemd Cgroup Enable (REQUIRED)

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## 🔶 ৩. Kubernetes Components (v1.29) ইনস্টল

### 🔸 পুরনো repo মুছে ফেলা

```bash
sudo rm /etc/apt/sources.list.d/kubernetes.list 2>/dev/null
```

### 🔸 নতুন অফিসিয়াল Repo যোগ করা

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
```

### 🔸 Install kubelet, kubeadm, kubectl

```bash\sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 🔶 ৪. Master-1 এ ক্লাস্টার ইনিশিয়ালাইজেশন

Master-1-এর প্রাইভেট IP (example):

```
10.0.10.113
```

### 🔸 Kubeadm Init Command

```bash
MASTER_1_IP="10.0.10.113"

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint "${MASTER_1_IP}:6443" \
  --upload-certs \
  --ignore-preflight-errors=NumCPU
```

### ✔️ Output থেকে যেগুলো সংরক্ষণ করবেন

* **Worker Join Token**
* **CA Cert Hash**
* **Control-plane certificate key** (Master-2 যোগ করার জন্য)

---

## 🔶 ৫. Kubeconfig সেটআপ (kubectl Enable)

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## 🔶 ৬. CNI Plugin (Flannel) ইনস্টল

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

কিছুক্ষণ পর স্টেটাস চেক:

```bash
kubectl get pods -n kube-system
```

---

## 🔶 ৭. Verification Checklist

| Task               | Status Check                    |
| ------------------ | ------------------------------- |
| containerd running | `systemctl status containerd`   |
| kubelet running    | `systemctl status kubelet`      |
| API server healthy | `kubectl get componentstatuses` |
| Nodes list         | `kubectl get nodes`             |
| Pods running       | `kubectl get pods -A`           |

---

## 🔶 Master-1 প্রস্তুত! 🔥

এখন আপনি Master-2 এবং Workers নোড যোগ করতে পারবেন।

যদি Master-2.md বা workers.md generate করতে চান—বলুন, সঙ্গে সঙ্গে তৈরি করে দেব।


#===================# master-1.sh #======================#

# Master-1 (Control Plane) Full Configuration Guide

## Step-by-Step Configuration (Same style as workers.md)

```bash
# System update
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

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

# Containerd install & Cgroup fix
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
# Cgroup fix
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Kubernetes tools install (v1.29)
sudo rm /etc/apt/sources.list.d/kubernetes.list 2>/dev/null
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize Master-1
MASTER_1_IP="10.0.10.113"
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint "${MASTER_1_IP}:6443" \
  --upload-certs \
  --ignore-preflight-errors=NumCPU

# Configure kubectl for the user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
