# 🤝 Master-2 (Secondary Control Plane) — Full Detailed Configuration

এই ডকুমেন্টে Master-2 নোডকে Master-1 ক্লাস্টারের সাথে HA Control Plane হিসেবে যুক্ত করার সম্পূর্ণ স্টেপ-by-স্টেপ গাইড দেওয়া হলো।

> **Note:** Master-2-কে join করার আগে অবশ্যই Master-1.md এর **Step 1, Step 2 এবং Step 3** (Prerequisites + containerd + Kubernetes tools) সম্পন্ন থাকতে হবে।

---

## 🔶 ১. সিস্টেম প্রি-রিকুইজিটস এবং Kubernetes Tools

Master-2 নোডে Master-1 এর মতোই নিম্নলিখিত সেটআপ করা থাকতে হবে:

* Swap disabled
* Kernel modules loaded
* containerd installed && SystemdCgroup=true
* kubeadm, kubelet, kubectl installed (v1.29)

যদি না করে থাকেন, Master-1.md এর Step 1–3 অনুসরণ করে সম্পন্ন করুন।

---

## 🔶 ২. Master-2 কে Control Plane হিসেবে Join করানো

Master-1 এ `kubeadm init` কমান্ড চালানোর পরে আপনি ৩টি গুরুত্বপূর্ণ জিনিস পাবেন:

### ✔️ ১) Token (worker এবং master যোগ করার জন্য)

### ✔️ ২) CA Cert Hash

### ✔️ ৩) Certificate Key (শুধু Control Plane join এর জন্য)

এই তথ্যগুলো ব্যাবহার করে Master-2 ক্লাস্টারে যোগ হবে।

### 🔸 Join Command Template

```bash
sudo kubeadm join <MASTER_IP>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<CA_HASH> \
  --control-plane \
  --certificate-key <CERT_KEY>
```

### 🔸 Example (Sample Values)

```bash
sudo kubeadm join 10.0.10.113:6443 \
  --token wy3vbu.wzwwr3uxtic46kmj \
  --discovery-token-ca-cert-hash sha256:bf5a5561d5d0096a221a4e8ab7a4d63d9ac42285fd7bb96c4b82ab7947fd631c \
  --control-plane \
  --certificate-key c72e6c4ae69ef70fb148dee167a92fede7476d3e165a10384586310a0aec535e
```

### 🔸 Join সফল হলে আপনি দেখতে পাবেন:

* etcd sync শুরু হবে
* API server, scheduler, controller-manager Master-2 তে configure হবে
* Certificates কপি হবে
* kubelet service auto-config হবে

---

## 🔶 ৩. Master-2 তে kubectl enable করা

Join complete হওয়ার পরে Master-2 নোডে kubectl চালানোর জন্য kubeconfig সেট করতে হবে:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

kubectl টেস্ট করুন:

```bash
kubectl get nodes
```

Master-2 এখন Ready দেখানো উচিত।

---

## 🔶 ৪. Verification Checklist (Highly Recommended)

Master-1 অথবা Master-2 যেকোনো একটি নোড থেকে নিচের কমান্ডগুলো চালিয়ে HA Control Plane চেক করুন:

### 🔸 Nodes check

```bash
kubectl get nodes -o wide
```

Expect:

* master-1 → Ready, ControlPlane
* master-2 → Ready, ControlPlane

### 🔸 Control plane Pods check

```bash
kubectl get pods -n kube-system -l tier=control-plane
```

সব Master component চলমান কিনা দেখুন:

* kube-apiserver
* kube-controller-manager
* kube-scheduler
* etcd

### 🔸 etcd Members check

```bash
kubectl exec -n kube-system etcd-master-1 -- etcdctl member list --write-out=table
```

Expected: 2 members (master-1, master-2)

---

## 🔶 ৫. Optional (Highly Recommended)

### Master-2 এ সময় sync নিশ্চিত করুন:

```bash
sudo timedatectl set-ntp true
```

### containerd status check:

```bash
systemctl status containerd
```

### kubelet logs (join failure হলে):

```bash
journalctl -u kubelet -f
```

---

## 🎉 Master-2 HA Control Plane সম্পূর্ণ প্রস্তুত!

এখন ক্লাস্টারে আপনি load-balanced Control Plane ব্যবহার করতে পারবেন এবং Worker নোডগুলো নিরাপদে যোগ করতে পারবেন।

আপনি চাইলে এখন **workers.md** ফাইল তৈরি করে দিই?
