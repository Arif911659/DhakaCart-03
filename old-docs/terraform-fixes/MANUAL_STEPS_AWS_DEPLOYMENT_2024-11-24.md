# 🔧 AWS Deployment - Manual Steps Guide

**তারিখ:** ২৪ নভেম্বর, ২০২৪  
**প্রজেক্ট:** DhakaCart HA Kubernetes Cluster  
**Region:** ap-southeast-1 (Singapore)

---

## 📋 Overview

এই document এ AWS এ HA Kubernetes cluster deploy করার জন্য **সব manual steps** বিস্তারিত বলা হয়েছে। প্রতিটি step follow করলে আপনি successfully deploy করতে পারবেন।

---

## ✅ Prerequisites Checklist

Deployment শুরু করার আগে এই checklist complete করুন:

- [ ] AWS Account আছে
- [ ] AWS Account এ billing enabled আছে
- [ ] AWS Access Key ID এবং Secret Access Key আছে
- [ ] Terraform installed আছে
- [ ] AWS CLI installed আছে
- [ ] kubectl installed আছে (optional, cluster access এর জন্য)
- [ ] Minimum $300-400 credit/balance আছে (monthly cost)

---

## 🔐 Step 1: AWS Account Setup

### 1.1 AWS Account Check করুন

1. AWS Console এ login করুন: https://console.aws.amazon.com
2. Billing dashboard check করুন
3. Account এ sufficient credit আছে কিনা verify করুন

**💡 Note:** এই cluster monthly ~$327 cost করবে

### 1.2 AWS Access Keys তৈরি করুন

**Option A: Root User (Not Recommended for Production)**

1. AWS Console → Your Name (top right) → Security Credentials
2. Access Keys → Create New Access Key
3. Download CSV file (এটা save করুন, পরে দেখাবে না!)

**Option B: IAM User (Recommended)**

1. AWS Console → IAM → Users → Create User
2. User name: `dhakacart-terraform`
3. Access type: Programmatic access
4. Permissions: Attach policies directly
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `IAMFullAccess` (or create custom policy)
5. Create user
6. **Save Access Key ID এবং Secret Access Key** (একবারই দেখাবে!)

**⚠️ Important:** 
- Access keys secure place এ save করুন
- Git এ commit করবেন না
- Share করবেন না

---

## 🛠️ Step 2: Local Machine Setup

### 2.1 Terraform Install করুন

**Linux (Ubuntu/Debian):**
```bash
# Update package list
sudo apt-get update

# Install required packages
sudo apt-get install -y software-properties-common

# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Add HashiCorp repository
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Install Terraform
sudo apt-get update
sudo apt-get install -y terraform

# Verify installation
terraform version
```

**macOS:**
```bash
# Using Homebrew
brew install terraform

# Verify
terraform version
```

**Windows:**
1. Download from: https://www.terraform.io/downloads
2. Extract ZIP file
3. Add to PATH
4. Verify: `terraform version`

### 2.2 AWS CLI Install করুন

**Linux:**
```bash
# Download AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install unzip if needed
sudo apt-get install -y unzip

# Extract
unzip awscliv2.zip

# Install
sudo ./aws/install

# Verify
aws --version
```

**macOS:**
```bash
# Using Homebrew
brew install awscli

# Verify
aws --version
```

**Windows:**
1. Download MSI installer: https://aws.amazon.com/cli/
2. Run installer
3. Verify: `aws --version`

### 2.3 kubectl Install করুন (Optional)

**Linux:**
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

**macOS:**
```bash
# Using Homebrew
brew install kubectl

# Verify
kubectl version --client
```

---

## 🔑 Step 3: AWS Credentials Configure করুন

### 3.1 AWS CLI Configure

```bash
# AWS credentials configure করুন
aws configure
```

**Enter করুন:**

1. **AWS Access Key ID:** `[আপনার Access Key ID]`
2. **AWS Secret Access Key:** `[আপনার Secret Access Key]`
3. **Default region name:** `ap-southeast-1`
4. **Default output format:** `json`

**💡 ব্যাখ্যা:**
- Access Key ID এবং Secret Access Key = Step 1.2 এ তৈরি করা keys
- Region = ap-southeast-1 (Singapore) - আমাদের cluster এখানে deploy হবে
- Output format = json (default, ভালো)

### 3.2 Credentials Verify করুন

```bash
# Test AWS connection
aws sts get-caller-identity
```

**✅ Expected Output:**
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/dhakacart-terraform"
}
```

যদি এই output দেখায়, তাহলে credentials ঠিক আছে! ✅

### 3.3 Permissions Check করুন

```bash
# Check EC2 permissions
aws ec2 describe-regions

# Check VPC permissions
aws ec2 describe-vpcs --max-items 1

# Check IAM permissions
aws iam get-user
```

যদি সব commands কাজ করে, তাহলে permissions ঠিক আছে! ✅

---

## 📝 Step 4: Terraform Variables File তৈরি করুন

### 4.1 Project Folder এ যান

```bash
cd /home/arif/DhakaCart-03/terraform/k8s-ha-cluster
```

### 4.2 terraform.tfvars File তৈরি করুন

```bash
# Example file copy করুন
cp terraform.tfvars.example terraform.tfvars

# File edit করুন
nano terraform.tfvars
# বা
vim terraform.tfvars
# বা
code terraform.tfvars  # VS Code
```

### 4.3 Variables Customize করুন (Optional)

**Default values ভালো, কিন্তু আপনি customize করতে পারেন:**

```hcl
# AWS Configuration
aws_region = "ap-southeast-1"  # ✅ Default ভালো

# Cluster Configuration
cluster_name = "dhakacart-k8s-ha"  # ✅ Default ভালো
environment  = "production"  # ✅ Default ভালো

# Network Configuration (যদি conflict হয় তাহলে change করুন)
vpc_cidr             = "10.0.0.0/16"  # ✅ Default ভালো
num_azs              = 3  # ✅ Default ভালো
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  # ✅ Default ভালো
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]  # ✅ Default ভালো

# Kubernetes Configuration
kubernetes_version = "1.28.0"  # ✅ Default ভালো
pod_cidr          = "192.168.0.0/16"  # ✅ Default ভালো
service_cidr      = "10.96.0.0/12"  # ✅ Default ভালো

# Instance Configuration (Cost optimize করতে পারেন)
master_instance_type = "t3.medium"  # ✅ Default ভালো (t3.small দিয়ে test করতে পারেন)
worker_instance_type = "t3.medium"  # ✅ Default ভালো
bastion_instance_type = "t3.micro"  # ✅ Default ভালো

# Node Count
num_masters = 3  # ✅ HA এর জন্য 3 প্রয়োজন
num_workers = 2  # ✅ Default ভালো (বাড়াতে পারেন)

# Security Configuration (⚠️ Important!)
bastion_allowed_cidr = "0.0.0.0/0"  # ⚠️ Production এ আপনার IP দিয়ে replace করুন
# Example: bastion_allowed_cidr = "203.0.113.0/32"  # আপনার IP

# Tags
tags = {
  Project     = "DhakaCart"
  Environment = "production"
  ManagedBy   = "Terraform"
}
```

**💡 Important Notes:**

1. **bastion_allowed_cidr:** 
   - Default: `0.0.0.0/0` (anyone can access)
   - Production এ আপনার IP address দিয়ে replace করুন
   - আপনার IP জানতে: `curl ifconfig.me` বা `curl ipinfo.io/ip`

2. **Instance Types:**
   - t3.medium = ~$30/month per instance
   - Cost কমাতে t3.small ব্যবহার করতে পারেন (testing এর জন্য)
   - Production এ t3.medium বা t3.large recommended

3. **Network CIDRs:**
   - Default values ভালো
   - শুধুমাত্র যদি conflict হয় (existing VPC থাকলে) তাহলে change করুন

### 4.4 File Save করুন

- `nano`: `Ctrl + O` (save), `Enter`, `Ctrl + X` (exit)
- `vim`: `:wq` (save and quit)
- VS Code: `Ctrl + S`

---

## 🚀 Step 5: Terraform Initialize করুন

### 5.1 Initialize করুন

```bash
# Project folder এ থাকুন
cd /home/arif/DhakaCart-03/terraform/k8s-ha-cluster

# Terraform initialize করুন
terraform init
```

**💡 এই command কী করছে:**
- Terraform plugins download করছে
- Modules download করছে
- Backend configure করছে

**✅ Expected Output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding hashicorp/tls versions matching "~> 4.0"...
- Installing hashicorp/aws v5.x.x...
- Installing hashicorp/tls v4.x.x...
...

Terraform has been successfully initialized!
```

**⏱️ Time:** ১-২ মিনিট

### 5.2 Errors হলে

**Error: "Failed to query available provider packages"**
- **Solution:** Internet connection check করুন

**Error: "Authentication failed"**
- **Solution:** `aws configure` আবার run করুন

**Error: "Permission denied"**
- **Solution:** AWS IAM permissions check করুন

---

## 📊 Step 6: Terraform Plan দেখুন

### 6.1 Plan Generate করুন

```bash
terraform plan
```

**💡 এই command কী করছে:**
- Infrastructure plan generate করছে
- কী কী resources create হবে দেখাচ্ছে
- কিন্তু create করছে না

**⏱️ Time:** ১-২ মিনিট

### 6.2 Plan Review করুন

**Expected Resources:**
- 1 VPC
- 3 Public Subnets
- 3 Private Subnets
- 3 NAT Gateways
- 1 Internet Gateway
- 3 Master Nodes (EC2 instances)
- 2 Worker Nodes (EC2 instances)
- 1 Bastion Host (EC2 instance)
- 2 Load Balancers
- Security Groups
- IAM Roles
- Target Groups

**Plan Output Example:**
```
Plan: 45 to add, 0 to change, 0 to destroy.
```

### 6.3 Plan Save করুন (Optional)

```bash
# Plan file এ save করুন
terraform plan -out=tfplan

# পরে apply করতে পারেন
terraform apply tfplan
```

---

## 💰 Step 7: Cost Estimation

### 7.1 Estimated Monthly Cost

**Resources এবং Cost:**

| Resource | Count | Monthly Cost (ap-southeast-1) |
|----------|-------|------------------------------|
| Master Nodes (t3.medium) | 3 | ~$90 |
| Worker Nodes (t3.medium) | 2 | ~$60 |
| Bastion (t3.micro) | 1 | ~$7 |
| NAT Gateways | 3 | ~$135 |
| Load Balancers | 2 | ~$35 |
| EBS Volumes | 6 | ~$12 |
| Data Transfer | Variable | ~$10-50 |
| **Total** | | **~$327-349/month** |

### 7.2 Cost Optimization Tips

1. **Testing এর জন্য:**
   - Instance types: t3.small ব্যবহার করুন
   - Workers: 1 node
   - NAT Gateways: 1 (single_nat_gateway = true)

2. **Production এর জন্য:**
   - Current setup optimal
   - Auto-scaling enable করুন

---

## 🎯 Step 8: Deploy Infrastructure

### 8.1 Apply করুন

```bash
terraform apply
```

**⚠️ Warning:** এই command run করলে AWS resources create হবে এবং charges apply হবে!

### 8.2 Confirmation

Terraform prompt করবে:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

**Type করুন:** `yes`

### 8.3 Deployment Process

**Timeline:**
- **0-2 minutes:** VPC, subnets, security groups create
- **2-5 minutes:** Load balancers create
- **5-10 minutes:** EC2 instances launch
- **10-15 minutes:** Kubernetes installation (cloud-init)
- **15-20 minutes:** Cluster initialization complete

**Total Time:** ~15-20 minutes

### 8.4 Monitor Progress

```bash
# Another terminal এ AWS Console check করুন
# বা
aws ec2 describe-instances --filters "Name=tag:Cluster,Values=kubeadm-ha" --query "Instances[*].[InstanceId,State.Name]"
```

---

## 📤 Step 9: Get Cluster Information

### 9.1 Outputs দেখুন

```bash
terraform output
```

**Key Outputs:**
- `api_server_endpoint` - Kubernetes API Server endpoint
- `bastion_ssh_command` - SSH command to bastion
- `bastion_public_ip` - Bastion IP address
- `master_nodes` - Master nodes information
- `worker_nodes` - Worker nodes information
- `kubeconfig_command` - Command to get kubeconfig
- `kubeadm_join_command_worker` - Join command for workers
- `kubeadm_join_command_master` - Join command for masters

### 9.2 SSH Key Location

```bash
# SSH private key location
ls -lh dhakacart-k8s-ha-key.pem

# Permissions check
chmod 400 dhakacart-k8s-ha-key.pem
```

**💡 Important:** এই key file secure রাখুন!

---

## 🔍 Step 10: Verify Deployment

### 10.1 Connect to Bastion

```bash
# Output থেকে SSH command copy করুন
terraform output bastion_ssh_command

# বা manually
ssh -i dhakacart-k8s-ha-key.pem ubuntu@<bastion-ip>
```

### 10.2 Connect to Master-1

```bash
# Bastion থেকে
ssh -i dhakacart-k8s-ha-key.pem ubuntu@<master1-private-ip>

# Master-1 এ
kubectl get nodes
```

**✅ Expected Output:**
```
NAME                    STATUS   ROLES           AGE   VERSION
master-1                Ready    control-plane   5m    v1.28.0
master-2                Ready    control-plane   4m    v1.28.0
master-3                Ready    control-plane   4m    v1.28.0
worker-1                 Ready    <none>          3m    v1.28.0
worker-2                 Ready    <none>          3m    v1.28.0
```

### 10.3 Check Pods

```bash
kubectl get pods --all-namespaces
```

**✅ Expected:** Calico pods running

---

## 📋 Summary of Manual Steps

### Required Steps (Must Do):

1. ✅ **AWS Account Setup** - Access keys তৈরি করুন
2. ✅ **Terraform Install** - Local machine এ install করুন
3. ✅ **AWS CLI Install** - Local machine এ install করুন
4. ✅ **AWS Credentials Configure** - `aws configure` run করুন
5. ✅ **terraform.tfvars Create** - Variables file তৈরি করুন
6. ✅ **Terraform Init** - `terraform init` run করুন
7. ✅ **Terraform Plan** - `terraform plan` run করুন (review)
8. ✅ **Terraform Apply** - `terraform apply` run করুন

### Optional Steps (Recommended):

- [ ] kubectl install করুন
- [ ] bastion_allowed_cidr customize করুন (security)
- [ ] Instance types customize করুন (cost optimization)
- [ ] Plan file save করুন

---

## ⚠️ Important Notes

### Security:

1. **SSH Keys:**
   - `dhakacart-k8s-ha-key.pem` file secure রাখুন
   - Git এ commit করবেন না
   - Share করবেন না

2. **AWS Credentials:**
   - Access keys secure রাখুন
   - `.aws/credentials` file permissions check করুন
   - Git এ commit করবেন না

3. **Bastion Access:**
   - Production এ `bastion_allowed_cidr` আপনার IP দিয়ে restrict করুন
   - Default `0.0.0.0/0` সবাই access করতে পারবে

### Cost Management:

1. **Monthly Cost:** ~$327-349
2. **Testing:** Resources destroy করুন: `terraform destroy`
3. **Monitoring:** AWS Cost Explorer use করুন

### Troubleshooting:

1. **Deployment fails:**
   - Check AWS console for errors
   - Check Terraform logs
   - Verify permissions

2. **Nodes not joining:**
   - Check cloud-init logs: `sudo journalctl -u cloud-init`
   - Check kubelet logs: `sudo journalctl -u kubelet`

3. **SSH connection fails:**
   - Check security groups
   - Verify key permissions: `chmod 400 key.pem`
   - Check bastion IP

---

## 🎉 Success Checklist

Deployment successful হলে:

- [ ] All nodes show `Ready` status
- [ ] API server accessible
- [ ] Calico pods running
- [ ] Can deploy test application
- [ ] Load balancers healthy
- [ ] SSH access working

---

## 📞 Next Steps

1. **Deploy Application:**
   ```bash
   kubectl apply -f ../../k8s/
   ```

2. **Setup Monitoring:**
   ```bash
   kubectl apply -f ../../monitoring/
   ```

3. **Setup Logging:**
   ```bash
   kubectl apply -f ../../logging/
   ```

---

## 📚 Additional Resources

- **Terraform Docs:** https://www.terraform.io/docs
- **AWS Docs:** https://docs.aws.amazon.com
- **Kubernetes Docs:** https://kubernetes.io/docs
- **Project README:** `README.md`
- **Fixes Documentation:** `FIXES_AND_EXPLANATIONS_2024-11-24.md`

---

**Created:** ২৪ নভেম্বর, ২০২৪  
**Last Updated:** ২৪ নভেম্বর, ২০২৪  
**Version:** 1.0  
**Status:** Complete ✅

---

## 🆘 Help & Support

যদি কোনো সমস্যা হয়:

1. **Check Logs:**
   ```bash
   terraform show
   terraform state list
   ```

2. **AWS Console:**
   - EC2 instances check করুন
   - VPC check করুন
   - Load balancers check করুন

3. **Documentation:**
   - `README.md` পড়ুন
   - `FIXES_AND_EXPLANATIONS_2024-11-24.md` পড়ুন

---

**Good Luck with your deployment! 🚀**

