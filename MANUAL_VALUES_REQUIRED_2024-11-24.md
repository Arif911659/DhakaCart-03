# 📝 Manual Values/Data/Variables Required - Complete Guide

**তারিখ:** ২৪ নভেম্বর, ২০২৪  
**প্রজেক্ট:** DhakaCart E-Commerce Platform  
**স্ট্যাটাস:** ✅ Complete Checklist

---

## 📋 Overview

এই document এ **পুরো project** এ কোথায় কোথায় manually value, data, বা variables দিতে হবে সেটা বিস্তারিত বলা হয়েছে। প্রতিটি component এর জন্য separate section আছে।

---

## 🎯 Quick Summary

### Must Provide (Required):
1. ✅ **AWS Credentials** - Terraform deployment এর জন্য
2. ✅ **terraform.tfvars** - Terraform variables file
3. ✅ **.env file** - Docker Compose এর জন্য (optional, defaults আছে)
4. ✅ **Kubernetes Secrets** - Database passwords (production এ change করতে হবে)
5. ✅ **AlertManager Config** - Email/SMS alerts (optional)
6. ✅ **Ansible Inventory** - Server IPs (যদি Ansible use করেন)

### Optional (Recommended):
- Bastion IP restriction (security)
- Email alert configuration
- Custom domain names
- Instance types customization

---

## ১. Terraform (AWS HA Kubernetes Cluster)

### Location: `terraform/k8s-ha-cluster/`

### ✅ Required: terraform.tfvars File তৈরি করুন

**File:** `terraform/k8s-ha-cluster/terraform.tfvars`

**Steps:**
```bash
cd terraform/k8s-ha-cluster
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### Values যা Provide করতে হবে:

#### 1. AWS Credentials (via AWS CLI)
**Not in terraform.tfvars** - Separate setup required

```bash
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: ap-southeast-1
# - Default output format: json
```

**💡 ব্যাখ্যা:** 
- AWS credentials `aws configure` দিয়ে setup করতে হবে
- terraform.tfvars এ credentials রাখবেন না (security risk)

#### 2. Cluster Configuration (Optional - Defaults আছে)

```hcl
# Default values ভালো, কিন্তু customize করতে পারেন:
cluster_name = "dhakacart-k8s-ha"  # ✅ Default ভালো
environment  = "production"         # ✅ Default ভালো
aws_region   = "ap-southeast-1"    # ✅ Default ভালো
```

#### 3. Network Configuration (যদি conflict হয়)

```hcl
# Default values:
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# ⚠️ Change করুন যদি:
# - Existing VPC same CIDR use করছে
# - Network conflict হয়
```

#### 4. Instance Configuration (Cost Optimization)

```hcl
# Default (Production):
master_instance_type = "t3.medium"   # ~$30/month per instance
worker_instance_type = "t3.medium"  # ~$30/month per instance
bastion_instance_type = "t3.micro"  # ~$7/month

# Testing/Development (Cost কমাতে):
master_instance_type = "t3.small"   # ~$15/month per instance
worker_instance_type = "t3.small"   # ~$15/month per instance
```

#### 5. Node Count (Customize করতে পারেন)

```hcl
num_masters = 3  # ✅ HA এর জন্য 3 প্রয়োজন (change করবেন না)
num_workers = 2  # ✅ Default ভালো (বাড়াতে পারেন)
```

#### 6. Security Configuration (⚠️ Important!)

```hcl
# Default (Open to all - Testing এর জন্য):
bastion_allowed_cidr = "0.0.0.0/0"

# ⚠️ Production এ আপনার IP দিয়ে replace করুন:
# আপনার IP জানতে: curl ifconfig.me
bastion_allowed_cidr = "203.0.113.0/32"  # আপনার IP
# বা
bastion_allowed_cidr = "203.0.113.0/24"  # আপনার office network
```

**💡 Security Best Practice:**
- Production এ সবসময় specific IP restrict করুন
- `0.0.0.0/0` সবাই access করতে পারবে (security risk)

#### 7. Kubernetes Version (Optional)

```hcl
kubernetes_version = "1.28.0"  # ✅ Default ভালো
# Latest version use করতে পারেন, কিন্তু test করুন
```

### Summary - Terraform:

| Item | Required? | Default | Change Needed? |
|------|-----------|---------|----------------|
| AWS Credentials | ✅ Yes | - | Via `aws configure` |
| terraform.tfvars | ✅ Yes | - | Create from example |
| Cluster Name | Optional | dhakacart-k8s-ha | Only if customize |
| Region | Optional | ap-southeast-1 | Only if different |
| Network CIDRs | Optional | 10.0.0.0/16 | Only if conflict |
| Instance Types | Optional | t3.medium | Cost optimization |
| Node Count | Optional | 3 masters, 2 workers | Scale as needed |
| **Bastion CIDR** | ⚠️ **Recommended** | 0.0.0.0/0 | **Production এ change করুন** |

---

## ২. Docker Compose (Local/Production)

### Location: `docker-compose.yml` এবং `docker-compose.prod.yml`

### ✅ Optional: .env File তৈরি করুন

**File:** `.env` (project root)

**কখন দরকার:**
- `docker-compose.yml` environment variables use করে
- Default values আছে, কিন্তু customize করতে পারেন

### Values যা Provide করতে হবে:

#### 1. Database Configuration

```env
# .env file
DB_USER=dhakacart
DB_PASSWORD=dhakacart123  # ⚠️ Production এ strong password
DB_NAME=dhakacart_db
DB_HOST=database
DB_PORT=5432
```

**💡 Note:**
- `docker-compose.yml` এ defaults আছে
- `.env` file না থাকলে defaults use হবে
- Production এ strong password ব্যবহার করুন

#### 2. Application Configuration

```env
NODE_ENV=development  # বা production
PORT=5000
```

#### 3. Redis Configuration

```env
REDIS_HOST=redis
REDIS_PORT=6379
```

#### 4. Frontend Configuration

```env
REACT_APP_API_URL=/api  # Docker network এর জন্য
# বা
REACT_APP_API_URL=http://localhost:5000/api  # Development এর জন্য
```

### docker-compose.prod.yml

**File:** `docker-compose.prod.yml`

**Hardcoded Values (Change করতে পারেন):**
```yaml
POSTGRES_USER: dhakacart
POSTGRES_PASSWORD: dhakacart123  # ⚠️ Change করুন production এ
POSTGRES_DB: dhakacart_db
```

**💡 Recommendation:**
- Production এ environment variables use করুন
- Hardcoded passwords avoid করুন

### Summary - Docker Compose:

| Item | Required? | Default | Change Needed? |
|------|-----------|---------|----------------|
| .env file | Optional | - | Customize করতে পারেন |
| DB_PASSWORD | Optional | dhakacart123 | **Production এ change করুন** |
| DB_USER | Optional | dhakacart | Only if customize |
| API_URL | Optional | /api | Only if different setup |

---

## ৩. Kubernetes Secrets

### Location: `k8s/secrets/db-secrets.yaml`

### ✅ Required: Database Password Change করুন

**File:** `k8s/secrets/db-secrets.yaml`

**Current (Development):**
```yaml
stringData:
  DB_USER: "dhakacart"
  DB_PASSWORD: "dhakacart123"  # ⚠️ Change in production!
```

**Production এ Change করুন:**
```yaml
stringData:
  DB_USER: "dhakacart"
  DB_PASSWORD: "YourStrongPassword123!@#"  # ⚠️ Strong password
```

**💡 Security Best Practices:**
1. **Strong Password ব্যবহার করুন:**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Example: `DhakaCart2024!Secure#Pass`

2. **Secrets Management:**
   - Production এ use করুন:
     - Sealed Secrets
     - External Secrets Operator
     - AWS Secrets Manager
     - HashiCorp Vault

3. **Base64 Encoding:**
   - Kubernetes automatically base64 encode করে
   - Manual encoding দরকার নেই

### How to Update:

```bash
# Edit file
nano k8s/secrets/db-secrets.yaml

# Apply to cluster
kubectl apply -f k8s/secrets/db-secrets.yaml

# Verify (password দেখাবে না, শুধু verify করবে)
kubectl get secret dhakacart-secrets -n dhakacart
```

### Summary - Kubernetes Secrets:

| Item | Required? | Current | Change Needed? |
|------|-----------|---------|----------------|
| DB_PASSWORD | ⚠️ **Yes (Production)** | dhakacart123 | **Strong password** |
| DB_USER | Optional | dhakacart | Only if customize |

---

## ৪. Monitoring - AlertManager

### Location: `monitoring/alertmanager/config.yml`

### ✅ Optional: Email/SMS Alerts Configure করুন

**File:** `monitoring/alertmanager/config.yml`

### Values যা Provide করতে হবে:

#### 1. SMTP Configuration (Email Alerts)

**Current (Example):**
```yaml
smtp_smarthost: 'smtp.gmail.com:587'
smtp_from: 'dhakacart-alerts@example.com'  # ⚠️ Change করুন
smtp_auth_username: 'dhakacart-alerts@example.com'  # ⚠️ Change করুন
smtp_auth_password: 'your-app-password'  # ⚠️ Change করুন
```

**Production Configuration:**
```yaml
smtp_smarthost: 'smtp.gmail.com:587'  # বা আপনার SMTP server
smtp_from: 'alerts@yourdomain.com'  # ✅ Your email
smtp_auth_username: 'alerts@yourdomain.com'  # ✅ Your email
smtp_auth_password: 'your-gmail-app-password'  # ✅ Gmail App Password
```

**💡 Gmail App Password তৈরি করুন:**
1. Google Account → Security
2. 2-Step Verification enable করুন
3. App passwords → Generate
4. Password copy করুন

#### 2. Email Recipients

**Current (Example):**
```yaml
receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'devops-team@dhakacart.com'  # ⚠️ Change করুন
```

**Production Configuration:**
```yaml
receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'your-team@yourdomain.com'  # ✅ Your email
      
  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@yourdomain.com, manager@yourdomain.com'  # ✅ Your emails
```

#### 3. Slack Integration (Optional)

**Uncomment এবং Configure করুন:**
```yaml
slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'  # ⚠️ Your webhook
    channel: '#alerts-critical'  # ✅ Your channel
```

**💡 Slack Webhook তৈরি করুন:**
1. Slack → Apps → Incoming Webhooks
2. Add to Slack
3. Channel select করুন
4. Webhook URL copy করুন

#### 4. PagerDuty Integration (Optional)

**Uncomment এবং Configure করুন:**
```yaml
pagerduty_configs:
  - service_key: 'your-pagerduty-service-key'  # ⚠️ Your key
```

### Summary - AlertManager:

| Item | Required? | Current | Change Needed? |
|------|-----------|---------|----------------|
| SMTP Email | Optional | example.com | **Production এ change করুন** |
| SMTP Password | Optional | your-app-password | **Gmail App Password** |
| Email Recipients | Optional | example emails | **Your team emails** |
| Slack Webhook | Optional | Commented | Uncomment + configure |
| PagerDuty | Optional | Commented | Uncomment + configure |

---

## ৫. Ansible Inventory

### Location: `ansible/inventory/hosts.ini`

### ✅ Required: Server IPs Update করুন

**File:** `ansible/inventory/hosts.ini`

**Current (Example):**
```ini
[production]
prod-web-1 ansible_host=192.168.1.10 ansible_user=ubuntu  # ⚠️ Change করুন
prod-web-2 ansible_host=192.168.1.11 ansible_user=ubuntu  # ⚠️ Change করুন
prod-db-1 ansible_host=192.168.1.20 ansible_user=ubuntu   # ⚠️ Change করুন
```

**Production Configuration:**
```ini
[production]
prod-web-1 ansible_host=YOUR_SERVER_IP_1 ansible_user=ubuntu  # ✅ Your IP
prod-web-2 ansible_host=YOUR_SERVER_IP_2 ansible_user=ubuntu  # ✅ Your IP
prod-db-1 ansible_host=YOUR_DB_SERVER_IP ansible_user=ubuntu  # ✅ Your IP
```

**💡 How to Get IPs:**
- AWS EC2 instances → Public/Private IPs
- Terraform output: `terraform output master_nodes`
- Manual server setup → Server IPs

### Domain Configuration (Optional)

**Current:**
```ini
[production:vars]
domain=dhakacart.com  # ⚠️ Change করুন
```

**Production:**
```ini
[production:vars]
domain=yourdomain.com  # ✅ Your domain
```

### Summary - Ansible:

| Item | Required? | Current | Change Needed? |
|------|-----------|---------|----------------|
| Server IPs | ✅ **Yes** | 192.168.x.x | **Your server IPs** |
| Username | Optional | ubuntu | Only if different |
| Domain | Optional | dhakacart.com | **Your domain** |

---

## ৬. Application Configuration

### Backend - Environment Variables

**Location:** `backend/server.js`

**Current (Uses Environment Variables):**
```javascript
const PORT = process.env.PORT || 5000;
const ADMIN_API_KEY = process.env.ADMIN_API_KEY;  // ⚠️ Set করুন
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'http://localhost:3000';
```

**💡 Set Environment Variables:**
```bash
# .env file বা environment
ADMIN_API_KEY=your-secure-api-key-here  # ⚠️ Generate করুন
CORS_ORIGIN=https://yourdomain.com  # Production এ
```

### Frontend - API URL

**Location:** `frontend/src/App.js`

**Current:**
```javascript
const API_URL_BASE = process.env.REACT_APP_API_URL || '/api';
```

**💡 Set Environment Variable:**
```bash
# Development
REACT_APP_API_URL=http://localhost:5000/api

# Production (Docker)
REACT_APP_API_URL=/api

# Production (Kubernetes)
REACT_APP_API_URL=https://api.yourdomain.com
```

### Summary - Application:

| Item | Required? | Default | Change Needed? |
|------|-----------|---------|----------------|
| ADMIN_API_KEY | Optional | - | Generate করুন |
| CORS_ORIGIN | Optional | localhost:3000 | Production domain |
| REACT_APP_API_URL | Optional | /api | Production URL |

---

## ৭. Grafana Configuration

### Location: `monitoring/grafana/datasources.yml`

**Current:** ✅ No manual changes needed

```yaml
datasources:
  - name: Prometheus
    url: http://prometheus:9090  # ✅ Auto-configured
```

**💡 Note:** 
- Default configuration ভালো
- Additional datasources add করতে পারেন

### Grafana Login Credentials

**Default (Hardcoded in docker-compose):**
```
Username: admin
Password: dhakacart123  # ⚠️ Production এ change করুন
```

**💡 Change Password:**
1. Grafana login করুন
2. Settings → Change Password
3. Strong password set করুন

---

## ৮. Backup Scripts

### Location: `scripts/backup/`

**Current:** ✅ No manual values needed

**💡 Optional Customization:**
- Backup retention period
- Backup location paths
- Cron schedule

---

## 📊 Complete Checklist

### Before First Deployment:

- [ ] **AWS Credentials** - `aws configure` run করেছেন
- [ ] **terraform.tfvars** - File তৈরি করেছেন
- [ ] **Bastion CIDR** - Production এ আপনার IP set করেছেন
- [ ] **Database Password** - Kubernetes secrets এ strong password
- [ ] **Email Alerts** - AlertManager এ email configure করেছেন (optional)
- [ ] **Ansible Inventory** - Server IPs update করেছেন (যদি use করেন)

### Before Production Deployment:

- [ ] **All Passwords** - Strong passwords set করেছেন
- [ ] **Bastion Access** - IP restricted করেছেন
- [ ] **Email Alerts** - Real email addresses configure করেছেন
- [ ] **Domain Names** - Your domain set করেছেন
- [ ] **SSL Certificates** - Configure করেছেন (Let's Encrypt)
- [ ] **Monitoring** - Grafana password change করেছেন

---

## 🔐 Security Checklist

### Passwords to Change:

1. ✅ **Database Password** (`k8s/secrets/db-secrets.yaml`)
   - Current: `dhakacart123`
   - Change to: Strong password (16+ chars)

2. ✅ **Grafana Password** (First login এ change করুন)
   - Current: `dhakacart123`
   - Change to: Strong password

3. ✅ **AWS Credentials** (Secure রাখুন)
   - Never commit to Git
   - Use IAM roles when possible

4. ✅ **SSH Keys** (Secure রাখুন)
   - File permissions: `chmod 400 key.pem`
   - Never share

### Access Restrictions:

1. ✅ **Bastion Host** - IP restrict করুন
2. ✅ **Database** - Private subnet এ (already done)
3. ✅ **API Endpoints** - Rate limiting enabled (already done)

---

## 📝 File-by-File Summary

### Files Requiring Manual Input:

| File | Required? | What to Change | Priority |
|------|-----------|----------------|----------|
| `terraform/k8s-ha-cluster/terraform.tfvars` | ✅ Yes | Create file, optional customization | High |
| `k8s/secrets/db-secrets.yaml` | ⚠️ Production | DB_PASSWORD | **Critical** |
| `monitoring/alertmanager/config.yml` | Optional | Email/SMS config | Medium |
| `ansible/inventory/hosts.ini` | If using | Server IPs | Medium |
| `.env` (root) | Optional | Environment variables | Low |
| `docker-compose.prod.yml` | Optional | DB password | Low |

### Files with Defaults (No Change Needed):

- ✅ `docker-compose.yml` - Uses environment variables
- ✅ `monitoring/grafana/datasources.yml` - Auto-configured
- ✅ `scripts/backup/*.sh` - Defaults work
- ✅ Most Kubernetes configs - Defaults work

---

## 🎯 Quick Reference

### Minimum Required (Quick Start):

```bash
# 1. AWS Credentials
aws configure

# 2. Terraform Variables
cd terraform/k8s-ha-cluster
cp terraform.tfvars.example terraform.tfvars
# Edit: bastion_allowed_cidr (optional but recommended)

# 3. Deploy
terraform init
terraform apply
```

### Production Ready:

```bash
# 1. All above +
# 2. Change database password
nano k8s/secrets/db-secrets.yaml

# 3. Configure email alerts
nano monitoring/alertmanager/config.yml

# 4. Update Ansible inventory (if using)
nano ansible/inventory/hosts.ini
```

---

## 💡 Best Practices

### 1. Secrets Management:

**❌ Don't:**
- Hardcode passwords in files
- Commit secrets to Git
- Share credentials

**✅ Do:**
- Use environment variables
- Use secrets management tools
- Rotate passwords regularly

### 2. Configuration Management:

**❌ Don't:**
- Use same passwords everywhere
- Use default passwords in production
- Skip security configurations

**✅ Do:**
- Use strong, unique passwords
- Change all default values
- Follow security best practices

### 3. Documentation:

**✅ Do:**
- Document all custom values
- Keep credentials secure
- Update this file when changes made

---

## 🆘 Troubleshooting

### "Where do I find X?"

- **AWS Credentials:** AWS Console → IAM → Users → Security Credentials
- **Server IPs:** AWS Console → EC2 → Instances
- **Your IP:** `curl ifconfig.me`
- **Gmail App Password:** Google Account → Security → App Passwords

### "What if I forget to change something?"

- **Database Password:** Change in `k8s/secrets/db-secrets.yaml` and reapply
- **Bastion Access:** Update security group in AWS Console
- **Email Alerts:** Update `monitoring/alertmanager/config.yml` and restart

---

## 📚 Related Documentation

- **Terraform Setup:** `terraform/k8s-ha-cluster/MANUAL_STEPS_AWS_DEPLOYMENT_2024-11-24.md`
- **Deployment Guide:** `DEPLOYMENT_GUIDE_BANGLA.md`
- **Fixes Documentation:** `terraform/k8s-ha-cluster/FIXES_AND_EXPLANATIONS_2024-11-24.md`

---

## ✅ Final Checklist

### Before Deployment:

- [ ] Read this document completely
- [ ] AWS credentials configured
- [ ] terraform.tfvars created
- [ ] All passwords changed (production)
- [ ] Security configurations reviewed
- [ ] Email alerts configured (optional)
- [ ] Ready to deploy!

---

**Created:** ২৪ নভেম্বর, ২০২৪  
**Last Updated:** ২৪ নভেম্বর, ২০২৪  
**Version:** 1.0  
**Status:** Complete ✅

---

**Remember:** 
- Default values testing এর জন্য ভালো
- Production এ সব default values change করুন
- Security first! 🔐

**Good Luck! 🚀**

