# 🔐 AWS Credentials Fix Guide

**সমস্যা:** InvalidClientTokenId - AWS credentials invalid

---

## ⚠️ Error Message

```
Error: InvalidClientTokenId: The security token included in the request is invalid.
```

---

## 🔧 Solution: Credentials আবার Configure করুন

### Method 1: AWS CLI Command (Recommended)

```bash
# Step 1: Credentials configure করুন
aws configure

# Enter your credentials:
# AWS Access Key ID: [YOUR_ACCESS_KEY_ID]
# AWS Secret Access Key: [YOUR_SECRET_ACCESS_KEY] (carefully copy, no extra spaces)
# Default region name: ap-southeast-1
# Default output format: (press Enter for default)
```

### Method 2: Manual File Edit

যদি `aws configure` কাজ না করে, manually edit করুন:

```bash
# Edit credentials file
nano ~/.aws/credentials

# File content should be:
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY

# Edit config file
nano ~/.aws/config

# File content should be:
[default]
region = ap-southeast-1
```

### Method 3: Environment Variables

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="ap-southeast-1"

# Test
aws sts get-caller-identity
```

---

## ✅ Verification

Credentials configure করার পর verify করুন:

```bash
# Test AWS connection
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "...",
#     "Account": "495599770374",
#     "Arn": "arn:aws:iam::495599770374:user/ap4x-poridhi"
# }

# Test Terraform
cd terraform/k8s-ha-cluster
terraform plan
```

---

## ⚠️ Common Issues

### Issue 1: Secret Key এ Special Characters

যদি secret key এ `+`, `/`, `=` characters থাকে:
- Copy করার সময় extra spaces avoid করুন
- Quotes ব্যবহার করুন environment variables এ

### Issue 2: Wrong Credentials

- Double-check Access Key ID এবং Secret Access Key
- AWS Console → IAM → Users → Your User → Security Credentials

### Issue 3: Credentials Expired

- Check if credentials are still active
- Generate new credentials if needed

### Issue 4: Region Mismatch

- Ensure region is `ap-southeast-1`
- Check `~/.aws/config` file

---

## 🔄 After Fix

Credentials fix করার পর:

```bash
cd terraform/k8s-ha-cluster

# Verify Terraform can connect
terraform init
terraform plan
```

---

## 📝 Quick Fix Command

```bash
# Quick re-configure
aws configure set aws_access_key_id "YOUR_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "YOUR_SECRET_ACCESS_KEY"
aws configure set default.region "ap-southeast-1"

# Test
aws sts get-caller-identity
```

---

**Note:** Secret key এ `+` character আছে, copy করার সময় careful হন - no extra spaces বা characters।

