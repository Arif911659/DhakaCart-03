# 🔐 নতুন AWS Credentials Setup Guide

**সমস্যা:** Current credentials invalid - নতুন credentials generate করতে হবে

---

## ⚠️ Current Status

```
Error: InvalidClientTokenId - The security token included in the request is invalid.
```

এটা mean করে:
- Access Key ID বা Secret Key wrong
- Credentials expired/deactivated
- **নতুন credentials generate করতে হবে**

---

## 🔧 Solution: নতুন Credentials Generate করুন

### Step 1: AWS Console থেকে New Access Key তৈরি করুন

1. **AWS Console** → **IAM** → **Users** → `ap4x-poridhi`
2. **Security credentials** tab → **Access keys** section
3. **Create access key** button click করুন
4. **Use case** select করুন: "Command Line Interface (CLI)"
5. **Next** → **Create access key**
6. **Important:** Access Key ID এবং Secret Access Key **immediately copy করুন** (একবারই দেখানো হবে!)

### Step 2: Credentials Download করুন

- CSV file download করুন (backup হিসেবে)
- অথবা Access Key ID এবং Secret Access Key manually copy করুন

### Step 3: Credentials Configure করুন

#### Method 1: AWS CLI Command (Recommended)

```bash
cd ~/DhakaCart-03/terraform/k8s-ha-cluster

# Credentials configure করুন
aws configure

# Enter:
# AWS Access Key ID: [নতুন Access Key ID paste করুন]
# AWS Secret Access Key: [নতুন Secret Key paste করুন] (carefully, no spaces)
# Default region name: ap-southeast-1
# Default output format: (press Enter for default)
```

#### Method 2: Environment Variables

```bash
# Temporary (current session only)
export AWS_ACCESS_KEY_ID="YOUR_NEW_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_NEW_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="ap-southeast-1"

# Test
aws sts get-caller-identity
```

#### Method 3: Manual File Edit

```bash
# Edit credentials file
nano ~/.aws/credentials

# Replace with new credentials:
[default]
aws_access_key_id = YOUR_NEW_ACCESS_KEY_ID
aws_secret_access_key = YOUR_NEW_SECRET_ACCESS_KEY

# Edit config file
nano ~/.aws/config

# Ensure region is set:
[default]
region = ap-southeast-1
```

---

## ✅ Verification

Credentials configure করার পর verify করুন:

```bash
# Test AWS connection
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "495599770374",
#     "Arn": "arn:aws:iam::495599770374:user/ap4x-poridhi"
# }
```

যদি এই output পান, credentials কাজ করছে! ✅

---

## 🚀 Terraform Test

Credentials verify করার পর:

```bash
cd ~/DhakaCart-03/terraform/k8s-ha-cluster

# Test Terraform
terraform plan
```

---

## ⚠️ Important Notes

### Secret Key Copy করার সময়:

1. **No extra spaces** - beginning বা end এ
2. **Complete key** - সব characters copy করুন
3. **Special characters** - `+`, `/`, `=` characters properly copy করুন
4. **No line breaks** - single line এ থাকতে হবে

### Security Best Practices:

1. **Never commit credentials** to Git
2. **Use IAM roles** instead of access keys when possible
3. **Rotate credentials** regularly
4. **Delete old credentials** after creating new ones

---

## 🔄 Old Credentials Delete করুন

নতুন credentials কাজ করলে, পুরানো credentials delete করুন:

1. **AWS Console** → **IAM** → **Users** → `ap4x-poridhi`
2. **Security credentials** tab → **Access keys**
3. পুরানো key এর **Delete** button click করুন

---

## 📞 যদি সমস্যা থাকে

যদি new credentials দিয়েও কাজ না করে:

1. **Check IAM permissions** - User এ proper policies attached আছে কিনা
2. **Check account status** - Account suspended নয় তো
3. **Check region** - ap-southeast-1 region available আছে কিনা
4. **Contact AWS support** - যদি account level issue হয়

---

## 🎯 Quick Checklist

- [ ] AWS Console → IAM → Users → ap4x-poridhi
- [ ] Security credentials → Create access key
- [ ] Access Key ID এবং Secret Key copy করুন
- [ ] `aws configure` run করুন
- [ ] `aws sts get-caller-identity` test করুন
- [ ] `terraform plan` test করুন

---

**Status:** Current credentials invalid ❌ | New credentials needed 🔑

