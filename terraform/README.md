# 🏗️ DhakaCart Terraform Infrastructure

এই directory এ **High-Availability Kubernetes Cluster** setup আছে।

## 📁 Directory Structure

```
terraform/
├── k8s-ha-cluster/          # HA Kubernetes Cluster Setup (নতুন!)
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf          # Variables
│   ├── outputs.tf           # Outputs
│   ├── README.md            # Complete guide
│   ├── modules/             # Terraform modules
│   └── cloud-init/          # Cloud-init scripts
└── README.md                # This file
```

## 🚀 Quick Start

### HA Kubernetes Cluster Deploy করুন:

```bash
# Navigate to cluster directory
cd k8s-ha-cluster

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy (takes 15-20 minutes)
terraform apply
```

## 📚 Documentation

- **HA Cluster Guide:** `k8s-ha-cluster/README.md` - Complete English guide
- **Deployment Guide (Bangla):** `../DEPLOYMENT_GUIDE_BANGLA.md` - Step-by-step in Bengali
- **Quick Reference:** `k8s-ha-cluster/DEPLOYMENT_SUMMARY.md`

## ✨ Features

- ✅ 3 Master Nodes (High Availability)
- ✅ 2+ Worker Nodes
- ✅ Internal Load Balancer (API Server)
- ✅ Public Load Balancer (Ingress)
- ✅ Bastion Host
- ✅ Multi-AZ Deployment
- ✅ Fully Automated Setup

## 📖 বিস্তারিত Guide

বাংলায় বিস্তারিত guide এর জন্য দেখুন:
- `../DEPLOYMENT_GUIDE_BANGLA.md` - Option 4: HA Kubernetes Cluster section

---

**Created:** November 2024  
**Region:** ap-southeast-1 (Singapore)

