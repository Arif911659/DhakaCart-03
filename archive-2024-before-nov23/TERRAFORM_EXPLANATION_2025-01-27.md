# 🏗️ Terraform Infrastructure as Code - Simple Guide
**Date:** 2025-01-27  
**For:** DevOps Engineer (Non-Coder Friendly)

---

## 🤔 What is Terraform?

**Terraform** is a tool that lets you define your **entire cloud infrastructure in code**.

Think of it like a **blueprint for your cloud**:

### Before Terraform (Old Way - Manual):
```
1. Log into AWS console
2. Click, click, click to create servers
3. Manually configure networks
4. Manually set up load balancers
5. Takes hours, easy to make mistakes ❌
```

### With Terraform (New Way - Code):
```
1. Write Terraform code (like a recipe)
2. Run: terraform apply
3. Everything created automatically!
4. Takes minutes, no mistakes ✅
```

---

## 🎯 What We're Building

I'm creating **Terraform code** that will create:

1. **VPC (Virtual Private Cloud)** - Your private network
2. **Subnets** - Public (for web) and Private (for database)
3. **Security Groups** - Firewall rules
4. **Load Balancer** - Distributes traffic
5. **Auto-Scaling Group** - Automatically adds/removes servers
6. **Database** - PostgreSQL in private subnet
7. **Redis Cache** - In private subnet

**Result:** Complete cloud infrastructure defined in code! ✅

---

## 📁 Files I'm Creating

### 1. `terraform/main.tf` - Main Infrastructure
**What it does:**
- Defines all your cloud resources
- Creates VPC, subnets, security groups
- Sets up load balancer and auto-scaling

**Think of it as:** The main blueprint

### 2. `terraform/variables.tf` - Configuration
**What it does:**
- Defines variables (like region, instance size)
- Makes it easy to change settings
- No need to edit main code

**Think of it as:** Settings you can adjust

### 3. `terraform/outputs.tf` - Results
**What it does:**
- Shows important information after creation
- Like load balancer URL, database endpoint
- Makes it easy to find what was created

**Think of it as:** Summary of what was built

### 4. `terraform/terraform.tfvars.example` - Example Config
**What it does:**
- Example configuration file
- Shows what values to set
- Copy and customize for your needs

**Think of it as:** Template for your settings

---

## 🏗️ What Infrastructure We're Creating

### Network Architecture:

```
Internet
    │
    ▼
┌─────────────────────────────────────┐
│  Load Balancer (Public)             │
│  - Distributes traffic               │
└─────────────────────────────────────┘
    │
    ├─────────────────┬─────────────────┐
    ▼                 ▼                 ▼
┌─────────┐      ┌─────────┐      ┌─────────┐
│ Web 1   │      │ Web 2   │      │ Web 3   │
│(Public) │      │(Public) │      │(Public) │
└─────────┘      └─────────┘      └─────────┘
    │                 │                 │
    └─────────────────┴─────────────────┘
                      │
                      ▼
            ┌─────────────────┐
            │  Backend API    │
            │  (Private)       │
            └─────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                            ▼
┌──────────────┐            ┌──────────────┐
│  Database    │            │   Redis      │
│  (Private)   │            │   (Private)  │
└──────────────┘            └──────────────┘
```

**Key Points:**
- ✅ **Public Subnets:** Web servers (accessible from internet)
- ✅ **Private Subnets:** Database and Redis (not accessible from internet)
- ✅ **Load Balancer:** Distributes traffic across multiple servers
- ✅ **Auto-Scaling:** Automatically adds servers when traffic increases

---

## 🔄 How It Works (Step by Step)

### Step 1: Write Terraform Code
```hcl
# This creates a VPC (network)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

### Step 2: Initialize Terraform
```bash
terraform init
```
**What it does:** Downloads required plugins

### Step 3: Plan (Preview)
```bash
terraform plan
```
**What it does:** Shows what will be created (without creating it)

### Step 4: Apply (Create)
```bash
terraform apply
```
**What it does:** Creates all the infrastructure!

### Step 5: Use It
- Your infrastructure is ready!
- Deploy your application
- Everything is automated

---

## 🎯 Benefits for Your Exam

### What the exam wants to see:
1. ✅ **Infrastructure as Code** - We have it!
2. ✅ **Cloud Infrastructure** - VPC, subnets, load balancer
3. ✅ **Auto-Scaling** - Handles traffic surges
4. ✅ **Network Segmentation** - Database in private subnet
5. ✅ **Version Control** - All code in Git
6. ✅ **Reproducible** - Can recreate entire infrastructure from code

### What this proves:
- You understand cloud architecture
- You can define infrastructure in code
- You can scale automatically
- You follow security best practices (private subnets)

---

## 🔧 What You Need to Configure

### 1. AWS Account (One-time setup)

**If you don't have AWS:**
1. Go to: https://aws.amazon.com
2. Create free account (12 months free tier)
3. Get your access keys

**If you have AWS:**
1. Get your access keys:
   - AWS Console → IAM → Users → Your User → Security Credentials
   - Create Access Key

### 2. Terraform Installation

**Install Terraform:**
```bash
# On Linux/Mac
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

**Or use package manager:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install terraform

# Mac
brew install terraform
```

### 3. Configure AWS Credentials

**Option 1: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option 2: AWS CLI**
```bash
aws configure
# Enter your access key, secret key, region
```

---

## 📊 What Gets Created

### Resources Created:

| Resource | Purpose | Count |
|----------|---------|-------|
| **VPC** | Private network | 1 |
| **Public Subnets** | Web servers | 2 (for redundancy) |
| **Private Subnets** | Database/Redis | 2 (for redundancy) |
| **Internet Gateway** | Internet access | 1 |
| **NAT Gateway** | Private subnet internet | 1 |
| **Load Balancer** | Traffic distribution | 1 |
| **Auto-Scaling Group** | Auto-scaling servers | 1 (3-10 instances) |
| **Security Groups** | Firewall rules | 4 |
| **RDS Database** | PostgreSQL | 1 |
| **ElastiCache** | Redis | 1 |

**Total:** ~15 resources created automatically!

---

## 💰 Cost Estimation

### AWS Free Tier (First 12 Months):
- ✅ 750 hours EC2 (t2.micro) - FREE
- ✅ 20 GB RDS storage - FREE
- ✅ 750 hours ElastiCache - FREE
- ✅ 15 GB data transfer - FREE

### After Free Tier (Estimated):
- **EC2 Instances:** ~$15/month (3x t3.small)
- **RDS Database:** ~$15/month (db.t3.micro)
- **ElastiCache:** ~$12/month (cache.t3.micro)
- **Load Balancer:** ~$20/month
- **NAT Gateway:** ~$32/month
- **Data Transfer:** ~$5/month

**Total:** ~$100/month (can optimize to ~$50)

**Note:** For exam/demo, you can use free tier or destroy after demo!

---

## 🚨 Important Concepts

### **VPC (Virtual Private Cloud)**
- **Meaning:** Your private network in AWS
- **Why:** Isolates your resources
- **Like:** Your own private internet

### **Subnets**
- **Public Subnet:** Can access internet directly
- **Private Subnet:** Cannot access internet directly (more secure)
- **Why:** Database should be private (not accessible from internet)

### **Security Groups**
- **Meaning:** Firewall rules
- **Why:** Control who can access what
- **Like:** Bouncer at a club (checks who can enter)

### **Load Balancer**
- **Meaning:** Distributes traffic across multiple servers
- **Why:** Handles more traffic, provides redundancy
- **Like:** Traffic director at intersection

### **Auto-Scaling**
- **Meaning:** Automatically adds/removes servers based on traffic
- **Why:** Handles traffic surges automatically
- **Like:** Automatic staffing based on customer count

---

## ✅ What This Achieves for Your Exam

### Exam Requirement #8: Infrastructure as Code ✅

**What the exam wants:**
- ✅ All infrastructure defined in code
- ✅ Version controlled in Git
- ✅ Reproducible (can recreate from code)
- ✅ Cloud infrastructure (VPC, subnets, load balancer)
- ✅ Auto-scaling configuration
- ✅ Network segmentation (private subnets)

**What we're building:**
- ✅ All of the above!

---

## 🔍 How to Use It

### 1. Review the Code
```bash
cd terraform
cat main.tf  # See what will be created
```

### 2. Customize (Optional)
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

### 3. Initialize
```bash
terraform init
```

### 4. Plan (Preview)
```bash
terraform plan
# Shows what will be created
```

### 5. Apply (Create)
```bash
terraform apply
# Type 'yes' when prompted
# Wait 5-10 minutes
# Done! ✅
```

### 6. Destroy (Clean Up)
```bash
terraform destroy
# Removes everything (saves money!)
```

---

## 🎓 Key Terms Explained Simply

### **Infrastructure as Code (IaC)**
- **Meaning:** Define infrastructure in code files
- **Why:** Version control, reproducible, automated
- **Like:** Blueprint for a house (but for cloud)

### **Terraform**
- **Meaning:** Tool for Infrastructure as Code
- **Why:** Works with AWS, GCP, Azure, etc.
- **Like:** Universal translator for cloud infrastructure

### **Resource**
- **Meaning:** A cloud component (server, database, network)
- **Why:** Terraform creates these
- **Like:** Building blocks

### **State File**
- **Meaning:** Terraform remembers what it created
- **Why:** Knows what to update/delete
- **Like:** Memory of what was built

---

## 📝 File Structure

After I create the files, you'll have:

```
terraform/
├── main.tf                    # Main infrastructure code
├── variables.tf               # Variables (settings)
├── outputs.tf                 # Outputs (results)
├── terraform.tfvars.example   # Example configuration
└── README.md                  # How to use
```

---

## ✅ Summary

**What we're doing:**
- Creating Terraform code that defines your entire cloud infrastructure

**Why it matters:**
- Required for your exam
- Makes infrastructure reproducible
- Saves time (hours → minutes)
- Follows DevOps best practices

**What you need to do:**
- Install Terraform (one-time)
- Configure AWS credentials (one-time)
- Run `terraform apply` to create infrastructure

---

## 🚀 Next Steps

After I create the Terraform files:
1. Review the code I created
2. Install Terraform (if not installed)
3. Configure AWS credentials
4. Run `terraform init`
5. Run `terraform plan` (preview)
6. Run `terraform apply` (create)

**Ready?** Let me create the Terraform infrastructure code now! 🏗️

---

**Created:** 2025-01-27  
**Purpose:** Help you understand Terraform in simple terms  
**Status:** Ready to implement

