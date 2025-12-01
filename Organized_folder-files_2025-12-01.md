# 📁 DhakaCart-03 Project - Organized Folder & Files Structure

**তারিখ:** ০১ ডিসেম্বর, ২০২৫ (Bangladesh UTC+6 Dhaka)  
**Last Updated:** ২০২৫-১২-০১  
**Status:** ✅ Fully Organized

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Root Directory Structure](#root-directory-structure)
3. [Application Code](#application-code)
4. [Infrastructure as Code](#infrastructure-as-code)
5. [Kubernetes Manifests](#kubernetes-manifests)
6. [Documentation](#documentation)
7. [Scripts](#scripts)
8. [Configuration Files](#configuration-files)
9. [Archive & Old Documentation](#archive--old-documentation)

---

## Project Overview

**DhakaCart E-Commerce Platform** - Enterprise-grade e-commerce solution with complete DevOps implementation.

### Key Directories:
- `backend/` - Backend API (Node.js/Express)
- `frontend/` - Frontend Application (React)
- `k8s/` - Kubernetes manifests and configurations
- `terraform/` - Infrastructure as Code (AWS)
- `docs/` - Project documentation
- `scripts/` - Automation and deployment scripts
- `old-docs/` - Archived documentation

---

## Root Directory Structure

```
DhakaCart-03/
├── README.md                          # Main project documentation
├── PROJECT_TRACKING_LOG.md            # Project tracking and logs
├── docker-compose.yml                  # Docker Compose for local development
├── docker-compose.local.yml            # Docker Compose for local testing
│
├── backend/                            # Backend application
├── frontend/                           # Frontend application
├── database/                           # Database scripts and migrations
├── k8s/                                # Kubernetes manifests
├── terraform/                          # Terraform infrastructure code
├── docs/                               # Project documentation
│   ├── architecture/                   # Architecture documentation
│   ├── guides/                         # Deployment guides
│   ├── troubleshooting/                # Troubleshooting guides
│   ├── runbooks/                       # Operational runbooks
│   └── Final Project — DhakaCart E-Commerce Reliability Challenge.md
├── scripts/                            # Automation scripts
│   └── k8s-deployment/                 # Kubernetes deployment scripts
├── old-docs/                           # Archived documentation
├── ansible/                            # Ansible playbooks (if any)
├── logging/                            # Logging configurations
├── monitoring/                         # Monitoring configurations
├── security/                           # Security configurations
├── testing/                             # Testing configurations
└── archive-2024-before-nov23/          # Old archive
```

---

## Application Code

### Backend (`backend/`)
- Node.js/Express API
- RESTful endpoints
- Database models and migrations
- Authentication and authorization

### Frontend (`frontend/`)
- React application
- UI components
- State management
- API integration

### Database (`database/`)
- Database schemas
- Migration scripts
- Seed data
- Backup scripts

---

## Infrastructure as Code

### Terraform (`terraform/`)

```
terraform/
└── simple-k8s/                        # Kubernetes cluster infrastructure
    ├── main.tf                         # Main Terraform configuration
    ├── variables.tf                    # Variable definitions
    ├── outputs.tf                      # Output values
    ├── alb-backend-config.tf           # Backend ALB configuration
    ├── post-apply.sh                   # Post-deployment automation
    ├── update-configmap-auto.sh        # ConfigMap auto-update script
    ├── README_AUTOMATION_2025-12-01.md # Automation guide
    └── nodes-config-steps/             # Node configuration scripts
```

**Key Files:**
- `main.tf` - VPC, EC2, ALB, Security Groups
- `alb-backend-config.tf` - Backend target group and ALB listener rules
- `post-apply.sh` - Complete automation script
- `outputs.tf` - Infrastructure outputs

---

## Kubernetes Manifests

### Kubernetes (`k8s/`)

```
k8s/
├── namespace.yaml                      # Namespace definition
├── deployments/                        # Deployment manifests
│   ├── frontend-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── postgres-deployment.yaml
│   └── redis-deployment.yaml
├── services/                           # Service definitions
│   └── services.yaml                   # All services (Frontend, Backend, DB, Redis)
├── volumes/                           # Persistent volumes
│   └── pvc.yaml                        # PVC definitions
├── configmaps/                         # Configuration maps
│   ├── app-config.yaml                 # Application configuration
│   └── app-config.yaml.template        # ConfigMap template
├── secrets/                            # Kubernetes secrets
│   └── secrets.yaml                    # Secret definitions
├── ingress/                            # Ingress configurations
│   └── ingress.yaml                    # Ingress rules
└── AUTOMATION_PLAN_2025-12-01.md       # Automation plan document
```

**Key Files:**
- `services/services.yaml` - All services with fixed NodePorts (30080, 30081)
- `configmaps/app-config.yaml` - Application configuration (auto-updated)
- `deployments/` - All application deployments

---

## Documentation

### Main Documentation (`docs/`)

```
docs/
├── README.md                            # Documentation index
├── architecture/                        # Architecture documentation
│   ├── DEPLOYMENT_ARCHITECTURE(29-11-25).md
│   └── system-architecture.md
├── guides/                              # Deployment and setup guides
│   ├── APPLICATION_DEPLOYMENT_GUIDE_2025-11-30.md
│   ├── ALB_PATH_ROUTING_SETUP.md
│   ├── DYNAMIC_LOAD_BALANCER_SETUP.md
│   ├── DOCKER_HUB_DEPLOYMENT.md
│   └── LOCAL_TESTING_GUIDE.md
├── troubleshooting/                      # Troubleshooting guides
├── runbooks/                            # Operational runbooks
├── LOCAL_K8S_SETUP.md                   # Local Kubernetes setup
├── PROJECT_COMPLETION_SUMMARY.md        # Project completion summary
└── Final Project — DhakaCart E-Commerce Reliability Challenge.md
```

**Key Documents:**
- `guides/APPLICATION_DEPLOYMENT_GUIDE_2025-11-30.md` - Complete deployment guide
- `architecture/DEPLOYMENT_ARCHITECTURE(29-11-25).md` - Infrastructure architecture
- `guides/ALB_PATH_ROUTING_SETUP.md` - ALB path-based routing setup

---

## Scripts

### Automation Scripts (`scripts/`)

```
scripts/
└── k8s-deployment/                     # Kubernetes deployment scripts
    ├── check-502-issue.sh              # 502 error diagnostic script
    ├── copy-k8s-to-master1.sh          # Copy k8s files to Master-1
    ├── sync-k8s-to-master1.sh          # Sync k8s files to Master-1
    ├── update-and-deploy.sh            # Update and deploy all
    └── update-configmap-with-lb.sh     # Update ConfigMap with LB URL
```

**Key Scripts:**
- `sync-k8s-to-master1.sh` - Sync k8s files to Master-1 node
- `update-and-deploy.sh` - Complete update and deployment automation
- `update-configmap-with-lb.sh` - Update ConfigMap with Load Balancer URL

### Terraform Scripts (`terraform/simple-k8s/`)

- `post-apply.sh` - Post-terraform apply automation
- `update-configmap-auto.sh` - Auto-update ConfigMap script

---

## Configuration Files

### Root Level Config Files

- `docker-compose.yml` - Docker Compose for production-like setup
- `docker-compose.local.yml` - Docker Compose for local development
- `README.md` - Main project documentation
- `PROJECT_TRACKING_LOG.md` - Project tracking and change log

---

## Archive & Old Documentation

### Old Documentation (`old-docs/`)

```
old-docs/
├── CHEAT_SHEET_BANGLA_2024-11-23.md
├── DEPLOYMENT_GUIDE_BANGLA.md
├── FILE_ORGANIZATION_2024-11-23.md
├── MANUAL_VALUES_REQUIRED_2024-11-24.md
├── NEXT_STEPS_BANGLA_2024-11-23.md
├── Project_Summary.md
├── QUICK_REFERENCE_BANGLA_2024-11-23.md
├── START_HERE_BANGLA_2024-11-23.md
├── STEP_BY_STEP_DEMO_BANGLA_2024-11-23.md
├── BACKEND_API_FIX.md                  # Troubleshooting docs
├── FIX_API_URL_NOW.md
├── LOAD_BALANCER_FIX_502.md
├── TROUBLESHOOT_502.md
├── POST_TERRAFORM_STEPS_2025-11-29.md
├── POST_TERRAFORM_STEPS_2025-11-29-(gemini).md
└── terraform-fixes/                    # Old Terraform fixes
```

**Note:** Files in `old-docs/` are archived but may be useful for reference.

---

## File Organization Rules

### ✅ Current Organization:

1. **Application Code** → `backend/`, `frontend/`, `database/`
2. **Kubernetes Manifests** → `k8s/`
3. **Infrastructure Code** → `terraform/`
4. **Documentation** → `docs/` (organized by type)
5. **Scripts** → `scripts/` (organized by purpose)
6. **Old/Archived Docs** → `old-docs/`

### 📝 Naming Conventions:

- **Documentation Files:** `DESCRIPTION_YYYY-MM-DD.md`
- **Scripts:** `purpose-description.sh`
- **Config Files:** `service-name-config.yaml`

### 🗂️ Folder Structure:

```
docs/
├── architecture/        # Architecture diagrams and docs
├── guides/             # Step-by-step guides
├── troubleshooting/    # Troubleshooting guides
└── runbooks/          # Operational runbooks

scripts/
└── k8s-deployment/    # Kubernetes deployment scripts
```

---

## Important Files Reference

### Quick Access:

| Purpose | Location |
|---------|----------|
| Main Documentation | `README.md` |
| Deployment Guide | `docs/guides/APPLICATION_DEPLOYMENT_GUIDE_2025-11-30.md` |
| Architecture | `docs/architecture/DEPLOYMENT_ARCHITECTURE(29-11-25).md` |
| Automation Plan | `k8s/AUTOMATION_PLAN_2025-12-01.md` |
| Terraform Automation | `terraform/simple-k8s/README_AUTOMATION_2025-12-01.md` |
| Sync Script | `scripts/k8s-deployment/sync-k8s-to-master1.sh` |
| Post-Apply Script | `terraform/simple-k8s/post-apply.sh` |

---

## Project Status

### ✅ Organized:
- All documentation files moved to appropriate folders
- All scripts organized in `scripts/k8s-deployment/`
- Old/troubleshooting docs moved to `old-docs/`
- Architecture docs in `docs/architecture/`
- Deployment guides in `docs/guides/`

### 📊 File Count:

- **Root Level:** 4 files (README.md, PROJECT_TRACKING_LOG.md, docker-compose files)
- **Documentation:** Organized in `docs/` and `old-docs/`
- **Scripts:** Organized in `scripts/k8s-deployment/`
- **Kubernetes:** All manifests in `k8s/`
- **Terraform:** All infrastructure code in `terraform/simple-k8s/`

---

## Maintenance Notes

### When Adding New Files:

1. **Documentation (.md):**
   - Use date format: `YYYY-MM-DD` (e.g., `2025-12-01`)
   - Place in appropriate `docs/` subfolder
   - If troubleshooting, use `docs/troubleshooting/`

2. **Scripts (.sh):**
   - Place in `scripts/` with appropriate subfolder
   - Make executable: `chmod +x script.sh`

3. **Config Files:**
   - Place in related service folder
   - Use descriptive names

4. **Old/Archived Files:**
   - Move to `old-docs/` if no longer actively used
   - Keep for reference

---

## Last Organization Date

**Date:** ০১ ডিসেম্বর, ২০২৫ (Bangladesh UTC+6 Dhaka)  
**Organized By:** AI Assistant  
**Status:** ✅ Complete

---

**Note:** This document should be updated whenever significant changes are made to the project structure.

