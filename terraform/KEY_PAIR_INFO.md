# 🔑 Auto-Generated Key Pair Information

## ✅ What Happens Automatically

When you run `terraform apply`, Terraform will:

1. ✅ **Automatically generate** an RSA 4096-bit key pair
2. ✅ **Create** the key pair in AWS
3. ✅ **Download** the private key to: `terraform/dhakacart-key.pem`
4. ✅ **Set permissions** to 0400 (read-only for owner)

**No manual steps required!** 🎉

---

## 📁 Key File Location

After running `terraform apply`, you'll find:

- **File:** `terraform/dhakacart-key.pem`
- **Location:** Same directory as your Terraform files
- **Permissions:** 0400 (read-only for owner)

---

## 🔐 Security Notes

### ⚠️ Important Security Rules:

1. **Never commit the key file to Git**
   - Already added to `.gitignore` ✅
   - The key file contains sensitive information

2. **Keep the key file secure**
   - Don't share it publicly
   - Don't email it
   - Store it safely

3. **Set correct permissions** (automatically done)
   ```bash
   chmod 400 terraform/dhakacart-key.pem
   ```

---

## 🚀 How to Use the Key

### SSH into EC2 Instance:

1. **Get instance IP:**
   - Go to AWS Console → EC2 → Instances
   - Find your instance and copy the Public IP

2. **SSH using the key:**
   ```bash
   ssh -i terraform/dhakacart-key.pem ubuntu@<instance-ip>
   ```

3. **Example:**
   ```bash
   ssh -i terraform/dhakacart-key.pem ubuntu@54.123.45.67
   ```

---

## 📋 Key Pair Details

### Key Information:

- **Key Name:** `dhakacart-key-YYYYMMDD` (date-based)
- **Type:** RSA 4096-bit
- **Algorithm:** RSA
- **Location:** AWS Key Pairs + Local file

### View Key Pair in AWS:

1. Go to AWS Console → EC2 → Key Pairs
2. Look for: `dhakacart-key-YYYYMMDD`
3. This is the public key (stored in AWS)
4. Private key is in: `terraform/dhakacart-key.pem`

---

## 🔄 Key Management

### If You Lose the Key:

**Option 1: Recreate Infrastructure**
```bash
terraform destroy
terraform apply
# New key will be generated
```

**Option 2: Create New Key Manually**
- Go to AWS Console → EC2 → Key Pairs
- Create new key pair
- Download it
- Update Terraform to use it (not recommended)

### If You Want to Use Existing Key:

If you already have a key pair you want to use:

1. **Don't set `key_name` variable** (leave it empty)
2. **Or** modify `main.tf` to use your existing key:
   ```hcl
   key_name = "your-existing-key-name"
   ```

**Note:** Auto-generation is recommended for simplicity!

---

## ✅ Verification

### Check Key File Exists:
```bash
ls -la terraform/dhakacart-key.pem
# Should show: -r-------- (read-only for owner)
```

### Check Key Pair in AWS:
```bash
aws ec2 describe-key-pairs --key-names dhakacart-key-*
```

### Test SSH Connection:
```bash
# Get instance IP first
ssh -i terraform/dhakacart-key.pem ubuntu@<instance-ip>
```

---

## 🎓 For Your Exam

This demonstrates:
- ✅ **Automated Infrastructure** - Key pair created automatically
- ✅ **Security Best Practices** - Private key stored securely
- ✅ **Infrastructure as Code** - Everything defined in code
- ✅ **No Manual Steps** - Fully automated

---

## 📝 Summary

**What You Get:**
- ✅ Auto-generated key pair
- ✅ Private key downloaded to local folder
- ✅ Correct permissions set automatically
- ✅ Ready to use for SSH access

**What You Need to Do:**
- ✅ Nothing! It's all automatic
- ✅ Just run `terraform apply`
- ✅ Key file will be in `terraform/` directory

**Status:** ✅ **Fully Automated!**

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27

