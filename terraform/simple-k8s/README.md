# Simple Kubernetes Infrastructure

এটা একটা simple Kubernetes cluster infrastructure তৈরি করে AWS তে।

## 🏗️ Architecture

```
Internet
    │
    ├─────► Bastion (Public IP) ──┐
    │                              │
    └─────► NAT Gateway            │
                │                  │ SSH
                │                  │
    ┌───────────▼──────────────────▼───────┐
    │        Private Subnet                │
    │  ┌──────────┐      ┌──────────┐     │
    │  │ Master-1 │      │ Worker-1 │     │
    │  │ Master-2 │      │ Worker-2 │     │
    │  └──────────┘      │ Worker-3 │     │
    │                    └──────────┘     │
    │  (No Public IP, Internet via NAT)  │
    └────────────────────────────────────┘
```

## 📦 যা তৈরি হবে:

- **1 Bastion Server** (Public subnet, SSH access)
- **2 Master Nodes** (Private subnet, no public IP)
- **3 Worker Nodes** (Private subnet, no public IP)
- **1 NAT Gateway** (Private subnet internet access)
- VPC, Subnets, Security Groups
- SSH Key Pair

## 🚀 Deploy করার নিয়ম:

### 1. AWS Credentials Configure করুন:

```bash
aws configure
# অথবা
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

### 2. Terraform Initialize করুন:

```bash
cd /home/arif/DhakaCart-03/terraform/simple-k8s
terraform init
```

### 3. Plan দেখুন:

```bash
terraform plan
```

### 4. Deploy করুন:

```bash
terraform apply
```

## 📝 Access করার নিয়ম:

### Step 1: Bastion এ SSH করুন

```bash
# Output থেকে পাবেন
ssh -i dhakacart-k8s-key.pem ubuntu@<BASTION_PUBLIC_IP>
```

### Step 2: SSH Key Bastion এ Copy করুন

```bash
scp -i dhakacart-k8s-key.pem dhakacart-k8s-key.pem ubuntu@<BASTION_PUBLIC_IP>:~/.ssh/
```

### Step 3: Bastion থেকে Master/Worker এ SSH করুন

```bash
# Bastion shell থেকে
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER_PRIVATE_IP>
```

## 🔧 Configuration

`variables.tf` file edit করে customize করুন:

```hcl
master_count = 2           # Master nodes সংখ্যা
worker_count = 3           # Worker nodes সংখ্যা
master_instance_type = "t2.medium"
worker_instance_type = "t2.medium"
```

## 💰 Cost Estimate

- **Bastion:** t2.micro = $0.0116/hour
- **Masters (2x):** t2.medium = $0.0464/hour each
- **Workers (3x):** t2.medium = $0.0464/hour each
- **NAT Gateway:** $0.045/hour + data transfer

**Total:** ~$0.30/hour = ~$7.20/day

## 🧹 Cleanup

```bash
terraform destroy
```

## 📋 Outputs

Deploy করার পর এগুলো পাবেন:

- `bastion_public_ip` - Bastion এর public IP
- `bastion_ssh_command` - SSH command
- `master_private_ips` - Master nodes IPs
- `worker_private_ips` - Worker nodes IPs
- `next_steps` - পরবর্তী কাজ

## ✅ Features

- ✅ Bastion publicly accessible
- ✅ Masters/Workers in private subnet (no public IP)
- ✅ Internet access via NAT Gateway
- ✅ SSH from bastion to all nodes
- ✅ Security groups configured
- ✅ Ready for Kubernetes installation

## 🔐 Security

- Masters/Workers শুধু bastion থেকে SSH access
- No public IP on masters/workers
- Security groups properly configured
- SSH key automatically generated

