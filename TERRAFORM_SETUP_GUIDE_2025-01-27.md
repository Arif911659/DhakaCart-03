# 🚀 Terraform Setup Guide - Quick Start
**Date:** 2025-01-27  
**Status:** Ready to Use

---

## ✅ What I Just Created

I've created **complete Terraform infrastructure code** for you:

1. ✅ **`main.tf`** - Complete cloud infrastructure (VPC, subnets, load balancer, auto-scaling, database, Redis)
2. ✅ **`variables.tf`** - All configurable settings
3. ✅ **`outputs.tf`** - Shows URLs and endpoints after creation
4. ✅ **`terraform.tfvars.example`** - Example configuration file
5. ✅ **`user_data.sh`** - Script that runs on EC2 instances
6. ✅ **`README.md`** - Complete documentation

**Location:** `terraform/` directory

---

## 🔧 Step-by-Step Setup (15 Minutes)

### Step 1: Install Terraform

**On Linux:**
```bash
# Download and install
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

**On Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install terraform
```

**On Mac:**
```bash
brew install terraform
```

---

### Step 2: Configure AWS Credentials

**Option 1: Environment Variables (Recommended)**
```bash
export AWS_ACCESS_KEY_ID="your-access-key-here"
export AWS_SECRET_ACCESS_KEY="your-secret-key-here"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option 2: AWS CLI**
```bash
aws configure
# Enter your access key, secret key, region
```

**How to get AWS credentials:**
1. Go to AWS Console → IAM → Users
2. Click your user → Security Credentials
3. Create Access Key
4. Copy Access Key ID and Secret Access Key

---

### Step 3: Create Configuration File

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

**Edit `terraform.tfvars` and set:**
```hcl
# REQUIRED: Set a strong database password
db_password = "YourStrongPassword123!"

# OPTIONAL: Set your AWS key pair name (for SSH access)
key_name = "your-key-pair-name"

# OPTIONAL: Change region
aws_region = "us-east-1"
```

**⚠️ Important:** Never commit `terraform.tfvars` to Git (it contains secrets)!

---

### Step 4: Deploy Infrastructure

```bash
# 1. Initialize Terraform (downloads plugins)
terraform init

# 2. Preview what will be created (no changes made)
terraform plan

# 3. Create infrastructure (takes 10-15 minutes)
terraform apply
# Type 'yes' when prompted

# 4. View outputs (URLs, endpoints)
terraform output
```

**Done!** ✅ Your infrastructure is created!

---

## 📊 What Gets Created

After running `terraform apply`, you'll have:

| Resource | Count | Purpose |
|----------|-------|---------|
| **VPC** | 1 | Your private network |
| **Public Subnets** | 2 | Web servers (accessible from internet) |
| **Private Subnets** | 2 | Database & Redis (not accessible from internet) |
| **Load Balancer** | 1 | Distributes traffic |
| **Auto-Scaling Group** | 1 | 2-10 servers (auto-scales) |
| **RDS Database** | 1 | PostgreSQL (in private subnet) |
| **ElastiCache Redis** | 1 | Redis cache (in private subnet) |
| **Security Groups** | 4 | Firewall rules |
| **NAT Gateway** | 1 | Internet access for private subnets |

**Total:** ~15 resources created automatically!

---

## 🎯 How to Access Your Application

After deployment, run:
```bash
terraform output load_balancer_url
```

**Example output:**
```
http://dhakacart-alb-123456789.us-east-1.elb.amazonaws.com
```

**Open this URL in your browser** to access your application! 🎉

---

## 💰 Cost Management

### Free Tier (First 12 Months):
- ✅ 750 hours EC2 (t2.micro) - FREE
- ✅ 20 GB RDS storage - FREE
- ✅ 750 hours ElastiCache - FREE

**Note:** The default config uses t3.small (not free tier). Change to `t3.micro` in `terraform.tfvars` for free tier.

### Estimated Monthly Cost (After Free Tier):
- **EC2:** ~$15/month (3x t3.small)
- **RDS:** ~$15/month
- **ElastiCache:** ~$12/month
- **Load Balancer:** ~$20/month
- **NAT Gateway:** ~$32/month
- **Total:** ~$100/month

### 💡 Cost Saving Tips:

1. **Use Free Tier:**
   ```hcl
   instance_type = "t3.micro"
   db_instance_class = "db.t3.micro"
   redis_node_type = "cache.t3.micro"
   ```

2. **Destroy When Not Using:**
   ```bash
   terraform destroy
   # This removes everything and stops charges
   ```

3. **Use Reserved Instances** (for long-term use)

---

## 🔍 Verify It's Working

### Check Load Balancer:
```bash
terraform output load_balancer_dns
curl http://$(terraform output -raw load_balancer_dns)
```

### Check Auto-Scaling:
```bash
# In AWS Console:
# EC2 → Auto Scaling Groups → dhakacart-asg
# Should show 3 instances running
```

### Check Database:
```bash
terraform output database_endpoint
# Should show: dhakacart-db.xxxxx.us-east-1.rds.amazonaws.com:5432
```

---

## 🐛 Troubleshooting

### Error: "No valid credential sources"
**Problem:** AWS credentials not configured

**Fix:**
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

---

### Error: "Invalid key pair"
**Problem:** Key pair name doesn't exist

**Fix:**
1. Create key pair in AWS Console (EC2 → Key Pairs)
2. Or remove `key_name` from `terraform.tfvars` (you won't be able to SSH)

---

### Error: "Insufficient instance capacity"
**Problem:** No capacity in that region/zone

**Fix:**
1. Try different AWS region
2. Or try different availability zone

---

### Can't Access Application
**Problem:** Application not responding

**Check:**
1. Security groups allow traffic (port 80, 443)
2. Auto-scaling group has running instances
3. Load balancer health checks are passing
4. Wait 5-10 minutes after deployment (containers need to start)

---

## 📝 Common Commands

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes (create/update)
terraform apply

# View outputs
terraform output

# Destroy everything
terraform destroy

# Format code
terraform fmt

# Validate code
terraform validate
```

---

## ✅ Checklist

Before you're done, make sure:

- [ ] Terraform installed (`terraform version`)
- [ ] AWS credentials configured
- [ ] `terraform.tfvars` created and configured
- [ ] `terraform init` completed
- [ ] `terraform plan` shows what will be created
- [ ] `terraform apply` completed successfully
- [ ] Application accessible via load balancer URL

**All checked?** You're ready! 🎉

---

## 🎓 For Your Exam

### What This Proves:

1. ✅ **Infrastructure as Code** - All infrastructure defined in code
2. ✅ **Cloud Infrastructure** - VPC, subnets, load balancer
3. ✅ **Auto-Scaling** - Handles traffic surges automatically
4. ✅ **Network Segmentation** - Database in private subnet
5. ✅ **Version Control** - All code in Git
6. ✅ **Reproducible** - Can recreate entire infrastructure from code

**This covers Exam Requirement #8: Infrastructure as Code** ✅

---

## 📚 Additional Resources

### Learn More:
- Terraform Docs: https://www.terraform.io/docs
- AWS Provider Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform Tutorial: https://learn.hashicorp.com/terraform

### Need Help?
- Check `terraform/README.md` for detailed documentation
- Read `TERRAFORM_EXPLANATION_2025-01-27.md` to understand concepts
- Check Terraform output for errors

---

## 🎯 Next Steps

Now that Terraform is set up:

1. ✅ **Test it** - Run `terraform apply` and see it work
2. ⏭️ **Next:** Fix security issues (remove hardcoded passwords)
3. ⏭️ **Then:** Set up Monitoring (Prometheus + Grafana)

---

## 📋 Summary

**What we created:**
- Complete Terraform infrastructure code
- VPC with public/private subnets
- Load balancer and auto-scaling
- Database and Redis in private subnets
- Security groups (firewall rules)

**What you need to do:**
1. Install Terraform
2. Configure AWS credentials
3. Create `terraform.tfvars`
4. Run `terraform apply`

**Status:** ✅ **Ready to use!**

---

**Created:** 2025-01-27  
**Status:** ✅ Complete  
**Next:** Install Terraform and deploy!

