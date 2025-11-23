# 🏗️ DhakaCart Terraform Infrastructure

This directory contains Terraform code to create the complete cloud infrastructure for DhakaCart.

## 📋 What This Creates

- ✅ **VPC** with public and private subnets
- ✅ **Load Balancer** for traffic distribution
- ✅ **Auto-Scaling Group** (2-10 instances)
- ✅ **RDS PostgreSQL** database (in private subnet)
- ✅ **ElastiCache Redis** (in private subnet)
- ✅ **Security Groups** (firewall rules)
- ✅ **NAT Gateway** for private subnet internet access

## 🚀 Quick Start

### Prerequisites

1. **Install Terraform:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install terraform
   
   # Or download from: https://www.terraform.io/downloads
   ```

2. **Configure AWS Credentials:**
   ```bash
   # Option 1: Environment variables
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   
   # Option 2: AWS CLI
   aws configure
   ```

3. **Create Configuration File:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

### Deploy Infrastructure

```bash
# 1. Initialize Terraform
terraform init

# 2. Preview what will be created
terraform plan

# 3. Create infrastructure (takes 10-15 minutes)
terraform apply
# Type 'yes' when prompted

# 4. View outputs (URLs, endpoints)
terraform output
```

### Destroy Infrastructure (Save Money!)

```bash
terraform destroy
# Type 'yes' when prompted
# This removes everything and stops charges
```

## 📁 Files

- **`main.tf`** - Main infrastructure code
- **`variables.tf`** - Variable definitions
- **`outputs.tf`** - Output values (URLs, endpoints)
- **`terraform.tfvars.example`** - Example configuration
- **`user_data.sh`** - Script that runs on EC2 instances
- **`README.md`** - This file

## ⚙️ Configuration

### Required Variables

Edit `terraform.tfvars` and set:

1. **`db_password`** - Strong password for database (REQUIRED)
2. **`key_name`** - Your AWS key pair name (optional, for SSH access)
3. **`aws_region`** - AWS region (default: us-east-1)

### Optional Variables

- `instance_type` - EC2 instance size (default: t3.small)
- `min_instances` - Minimum servers (default: 2)
- `max_instances` - Maximum servers (default: 10)
- `desired_instances` - Desired servers (default: 3)

## 📊 Outputs

After running `terraform apply`, you'll get:

- **Load Balancer URL** - Access your application here
- **Database Endpoint** - For connecting to database
- **Redis Endpoint** - For connecting to Redis
- **VPC ID** - For reference
- **Security Group IDs** - For reference

## 💰 Cost Estimation

### AWS Free Tier (First 12 Months):
- ✅ 750 hours EC2 (t2.micro) - FREE
- ✅ 20 GB RDS storage - FREE
- ✅ 750 hours ElastiCache - FREE

### After Free Tier:
- **EC2:** ~$15/month (3x t3.small)
- **RDS:** ~$15/month (db.t3.micro)
- **ElastiCache:** ~$12/month
- **Load Balancer:** ~$20/month
- **NAT Gateway:** ~$32/month
- **Total:** ~$100/month

**Tip:** Use `terraform destroy` when not testing to avoid charges!

## 🔒 Security Features

- ✅ Database in private subnet (not accessible from internet)
- ✅ Redis in private subnet (not accessible from internet)
- ✅ Security groups restrict access
- ✅ Only load balancer accessible from internet
- ✅ Database encrypted at rest

## 🐛 Troubleshooting

### Error: "No valid credential sources"
- **Fix:** Configure AWS credentials (see Prerequisites)

### Error: "Invalid key pair"
- **Fix:** Create a key pair in AWS Console or remove `key_name` variable

### Error: "Insufficient instance capacity"
- **Fix:** Try a different AWS region or instance type

### Can't access application after deployment
- **Check:** Security groups allow traffic
- **Check:** Auto-scaling group has running instances
- **Check:** Load balancer health checks are passing

## 📚 Learn More

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## ✅ For Your Exam

This Terraform code demonstrates:
- ✅ Infrastructure as Code (IaC)
- ✅ Cloud infrastructure provisioning
- ✅ Auto-scaling configuration
- ✅ Network segmentation (private subnets)
- ✅ Load balancing
- ✅ Security best practices

**Status:** ✅ Ready to use!

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27

