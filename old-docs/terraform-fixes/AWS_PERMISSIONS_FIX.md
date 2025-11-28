# 🔐 AWS Permissions Fix Guide

**তারিখ:** ২৪ নভেম্বর, ২০২৪  
**সমস্যা:** Terraform apply করার সময় permission errors

---

## ❌ পাওয়া Errors

### Error ১: IAM Role Tag Permission
```
Error: iam:TagRole permission denied
```

**সমাধান:** ✅ **Fixed** - IAM role এ tags disable করা হয়েছে

### Error ২: EC2 Instance Creation Permission
```
Error: ec2:RunInstances permission denied
User: arn:aws:iam::495599770374:user/ap4x-poridhi 
is not authorized to perform: ec2:RunInstances
with an explicit deny in an identity-based policy
```

**সমাধান:** ⚠️ **AWS IAM Policy Fix দরকার**

---

## 🔧 EC2 Permission Fix (AWS Console)

### Option 1: IAM Policy Update (Recommended)

আপনার IAM user (`ap4x-poridhi`) এর policy তে এই permissions যোগ করুন:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateTags",
        "ec2:TerminateInstances",
        "ec2:StopInstances",
        "ec2:StartInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

### Option 2: AWS Console থেকে Fix

1. **AWS Console** → **IAM** → **Users** → `ap4x-poridhi`
2. **Permissions** tab → **Add permissions** → **Attach policies directly**
3. এই policy attach করুন:
   - `AmazonEC2FullAccess` (বা custom policy with above permissions)

### Option 3: Explicit Deny Remove করুন

যদি কোন policy তে **explicit deny** থাকে EC2 resources এর জন্য, সেটা remove করুন:

1. **IAM** → **Policies** → আপনার user এর policies
2. **Explicit Deny** statement খুঁজুন
3. EC2 related deny statements remove করুন

---

## ✅ Verification

Permission fix করার পর verify করুন:

```bash
# Test EC2 permission
aws ec2 describe-instances --region ap-southeast-1

# Test IAM permission (if needed)
aws iam list-roles --region ap-southeast-1
```

---

## 📝 Required Permissions Summary

Terraform deployment এর জন্য minimum permissions:

### EC2 Permissions:
- `ec2:RunInstances` - Instance create
- `ec2:DescribeInstances` - Instance info
- `ec2:DescribeImages` - AMI lookup
- `ec2:CreateTags` - Resource tagging
- `ec2:TerminateInstances` - Cleanup

### VPC Permissions:
- `ec2:CreateVpc`, `ec2:DescribeVpcs`
- `ec2:CreateSubnet`, `ec2:DescribeSubnets`
- `ec2:CreateSecurityGroup`, `ec2:DescribeSecurityGroups`
- `ec2:CreateInternetGateway`, `ec2:CreateNatGateway`
- `ec2:CreateRouteTable`, `ec2:CreateRoute`

### Load Balancer Permissions:
- `elasticloadbalancing:CreateLoadBalancer`
- `elasticloadbalancing:DescribeLoadBalancers`
- `elasticloadbalancing:CreateTargetGroup`
- `elasticloadbalancing:CreateListener`

### IAM Permissions (Optional):
- `iam:CreateRole` - IAM role create
- `iam:AttachRolePolicy` - Policy attach
- `iam:CreateInstanceProfile` - Instance profile

---

## 🚀 After Fix

Permission fix করার পর:

```bash
cd terraform/k8s-ha-cluster

# Retry deployment
terraform apply
```

---

## 📞 Support

যদি permission fix করার পরও সমস্যা থাকে:

1. Check AWS CloudTrail logs for detailed error
2. Verify IAM policy syntax
3. Check for service control policies (SCP) at organization level
4. Contact AWS administrator for policy updates

---

**Status:** IAM Role tags fixed ✅ | EC2 permissions need AWS-side fix ⚠️

