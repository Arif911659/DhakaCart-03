# 🚀 Node Configuration Automation

এই directory তে Kubernetes nodes configure করার জন্য automation scripts আছে।

## 📁 File Structure

```
nodes-config-steps/
├── AUTOMATION_PLAN_2025-11-29.md    # Detailed automation plan
├── automate-node-config.sh          # Main script (run this!)
├── extract-terraform-outputs.sh      # Extract Terraform values
├── generate-scripts.sh               # Generate scripts from templates
├── upload-to-bastion.sh             # Upload files to Bastion
│
├── templates/                        # Template files
│   ├── master-1.sh.template
│   ├── master-2.sh.template
│   └── workers.sh.template
│
├── generated/                        # Auto-generated scripts (gitignored)
│   ├── master-1.sh
│   ├── master-2.sh
│   └── workers.sh
│
└── master-1.sh, master-2.sh, workers.sh  # Original scripts (backup)
```

## 🎯 Quick Start

### Step 1: After Terraform Apply

```bash
cd terraform/simple-k8s/nodes-config-steps
./automate-node-config.sh
```

এই script automatically:
- ✅ Terraform outputs extract করবে
- ✅ Dynamic IPs দিয়ে scripts generate করবে
- ✅ Files Bastion এ upload করবে

### Step 2: SSH to Bastion

Script শেষে দেখানো IP দিয়ে Bastion এ connect করুন:

```bash
ssh -i dhakacart-k8s-key.pem ubuntu@<BASTION_IP>
```

### Step 3: Configure Nodes

Bastion এ scripts ready থাকবে `~/nodes-config/` directory তে:

```bash
# Master-1 configure করুন
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER_1_IP>
cd ~/nodes-config && ./master-1.sh

# Master-2 configure করুন (Master-1 init এর পর)
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER_2_IP>
cd ~/nodes-config && ./master-2.sh

# Workers configure করুন
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<WORKER_IP>
cd ~/nodes-config && ./workers.sh
```

## 📋 Prerequisites

1. **Terraform Applied:** `terraform apply` complete হতে হবে
2. **jq or python3:** JSON parsing এর জন্য
   ```bash
   sudo apt-get install jq  # or python3
   ```
3. **SSH Access:** Bastion এ SSH access থাকতে হবে

## 🔧 Manual Steps (If Needed)

যদি automation কাজ না করে, individual scripts run করতে পারেন:

```bash
# Step 1: Extract outputs
./extract-terraform-outputs.sh

# Step 2: Generate scripts
./generate-scripts.sh

# Step 3: Upload to Bastion
./upload-to-bastion.sh
```

## 📚 Documentation

বিস্তারিত plan এবং process জানতে দেখুন:
- `AUTOMATION_PLAN_2025-11-29.md` - Complete automation plan

## ⚠️ Important Notes

1. **Join Tokens:** Master-2 এবং Workers scripts এ join tokens manually add করতে হবে Master-1 init এর পর
2. **IPs:** সব IPs automatically extract হবে - manual entry এর দরকার নেই
3. **Generated Files:** `generated/` directory gitignore করা আছে

## 🐛 Troubleshooting

### Error: Terraform state not found
```bash
# Solution: Run terraform apply first
cd ../../
terraform apply
```

### Error: jq or python3 not found
```bash
# Solution: Install jq
sudo apt-get install jq
```

### Error: Cannot connect to Bastion
```bash
# Check:
# 1. Security groups allow SSH from your IP
# 2. Bastion IP is correct
# 3. Key file permissions (should be 400)
chmod 400 ../dhakacart-k8s-key.pem
```

## ✅ Success Criteria

Automation successful যখন:
- ✅ Scripts generated with correct IPs
- ✅ Files uploaded to Bastion
- ✅ Ready to execute in < 3 minutes

---

**Created:** ২৯ নভেম্বর, ২০২৫  
**Status:** Ready to Use 🚀

