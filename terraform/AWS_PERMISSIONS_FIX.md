# 🔐 AWS Permissions Fix - Free Tier Account
**Date:** 2025-01-27  
**Issue:** IAM user doesn't have permissions for RDS and ElastiCache

---

## 🐛 The Problem

Your AWS IAM user `3z0k-poridhi` doesn't have permissions to:
- Create RDS DB Subnet Groups
- Create ElastiCache Subnet Groups

**Error:**
```
AccessDenied: User is not authorized to perform: rds:CreateDBSubnetGroup
AccessDenied: User is not authorized to perform: elasticache:CreateCacheSubnetGroup
```

---

## ✅ Solution 1: Add IAM Permissions (Recommended)

### Step 1: Go to IAM Console

1. Go to: https://console.aws.amazon.com/iam/
2. Click **Users** (left sidebar)
3. Find and click your user: `3z0k-poridhi`

### Step 2: Add Permissions

**Option A: Attach AWS Managed Policy (Easiest)**

1. Click **Add permissions** button
2. Select **Attach policies directly**
3. Search and select these policies:
   - ✅ `AmazonRDSFullAccess` (for database)
   - ✅ `AmazonElastiCacheFullAccess` (for Redis)
4. Click **Next** → **Add permissions**

**Option B: Create Custom Policy (More Secure)**

1. Click **Add permissions** → **Create inline policy**
2. Click **JSON** tab
3. Paste this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:*",
        "elasticache:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

4. Click **Next** → Name it: `DhakaCartTerraformPolicy`
5. Click **Create policy**

### Step 3: Wait a Few Seconds

AWS permissions can take 10-30 seconds to propagate.

### Step 4: Retry Terraform

```bash
terraform apply
```

**Done!** ✅

---

## ✅ Solution 2: Use Root Account (Not Recommended)

**⚠️ Warning:** Using root account is not secure for production!

If you're using root account:
1. Make sure you're logged in as root
2. Permissions should work automatically
3. But **don't use root for production!**

---

## ✅ Solution 3: Simplified Version (Without RDS/ElastiCache)

If you can't get permissions, I can create a simplified version that:
- ✅ Creates VPC, subnets, load balancer
- ✅ Creates auto-scaling group
- ✅ Uses Docker Compose with local PostgreSQL/Redis (in containers)

**This still demonstrates Infrastructure as Code!**

Let me know if you want this version.

---

## 🔍 Check Current Permissions

### See What Permissions You Have:

```bash
# Check your current user
aws sts get-caller-identity

# List attached policies
aws iam list-attached-user-policies --user-name 3z0k-poridhi

# List inline policies
aws iam list-user-policies --user-name 3z0k-poridhi
```

---

## 📋 Required Permissions Summary

For Terraform to work, your IAM user needs:

### RDS Permissions:
- `rds:CreateDBSubnetGroup`
- `rds:CreateDBInstance`
- `rds:DescribeDBSubnetGroups`
- `rds:*` (or specific permissions)

### ElastiCache Permissions:
- `elasticache:CreateCacheSubnetGroup`
- `elasticache:CreateCacheCluster`
- `elasticache:DescribeCacheSubnetGroups`
- `elasticache:*` (or specific permissions)

### Other Required Permissions (probably already have):
- `ec2:*` (for VPC, subnets, instances)
- `elasticloadbalancing:*` (for load balancer)
- `autoscaling:*` (for auto-scaling)

---

## 🎯 Quick Fix Steps

1. **Go to IAM Console:** https://console.aws.amazon.com/iam/
2. **Click Users** → Find `3z0k-poridhi`
3. **Click Add permissions**
4. **Attach policies:**
   - `AmazonRDSFullAccess`
   - `AmazonElastiCacheFullAccess`
5. **Wait 30 seconds**
6. **Run:** `terraform apply` again

---

## 💡 Free Tier Considerations

### Free Tier Includes:
- ✅ 750 hours EC2 (t2.micro) - FREE
- ✅ 20 GB RDS storage - FREE
- ✅ 750 hours ElastiCache - FREE

**But you still need IAM permissions to create them!**

### Cost After Free Tier:
- RDS: ~$15/month (db.t3.micro)
- ElastiCache: ~$12/month (cache.t3.micro)

**Tip:** Destroy infrastructure when not using: `terraform destroy`

---

## 🔒 Security Best Practice

**For Production:**
- Don't use `FullAccess` policies
- Create custom policies with minimum required permissions
- Use separate IAM users for different purposes

**For Learning/Exam:**
- `FullAccess` policies are okay
- Easier to manage
- Good for getting started

---

## ✅ After Adding Permissions

Once permissions are added:

1. **Wait 30 seconds** (for propagation)
2. **Run terraform again:**
   ```bash
   terraform apply
   ```
3. **It should work now!** ✅

---

## 🐛 Still Having Issues?

### Check:
1. ✅ Permissions attached correctly?
2. ✅ Waited 30 seconds after adding?
3. ✅ Using correct AWS account?
4. ✅ Credentials configured correctly?

### Try:
```bash
# Test RDS permissions
aws rds describe-db-subnet-groups --region ap-southeast-1

# Test ElastiCache permissions
aws elasticache describe-cache-subnet-groups --region ap-southeast-1
```

If these commands work, Terraform should work too!

---

## 📝 Summary

**Problem:** IAM user lacks RDS and ElastiCache permissions

**Solution:** Add IAM policies:
- `AmazonRDSFullAccess`
- `AmazonElastiCacheFullAccess`

**Steps:**
1. IAM Console → Users → Your User
2. Add permissions → Attach policies
3. Select the two policies above
4. Wait 30 seconds
5. Run `terraform apply` again

**Status:** Should work after adding permissions! ✅

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27

