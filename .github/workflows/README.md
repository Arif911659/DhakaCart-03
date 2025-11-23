# GitHub Actions Workflows

This directory contains CI/CD workflows for DhakaCart.

## 📁 Files

### 1. `ci.yml` - Continuous Integration
**When it runs:** On every push and pull request  
**What it does:**
- Runs tests (backend and frontend)
- Builds Docker images (test build)
- Scans for security vulnerabilities
- Checks code quality

**Status:** ✅ Ready to use

---

### 2. `cd.yml` - Continuous Deployment
**When it runs:** On push to `main` branch  
**What it does:**
- Builds Docker images
- Pushes images to Docker Hub
- Deploys to Kubernetes (if configured)
- Performs health checks

**Status:** ✅ Ready to use (requires GitHub secrets)

---

### 3. `docker-build.yml` - Docker Image Builder
**When it runs:** 
- Manually (workflow_dispatch)
- Daily at 2 AM UTC (scheduled)

**What it does:**
- Builds Docker images
- Optionally pushes to Docker Hub
- Useful for manual builds

**Status:** ✅ Ready to use

---

## 🔧 Setup Instructions

### Step 1: Add GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add these secrets:

1. **DOCKER_USERNAME**
   - Value: `arifhossaincse22` (or your Docker Hub username)

2. **DOCKER_PASSWORD**
   - Value: Your Docker Hub password or access token

3. **KUBECONFIG** (Optional - only if deploying to Kubernetes)
   - Value: Your Kubernetes configuration file content

### Step 2: Test the Workflows

1. Make a small change to your code
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. Go to GitHub → Actions tab
4. Watch the workflows run!

---

## 📊 Workflow Status

You can check workflow status:
- In GitHub: Go to **Actions** tab
- Via API: Use GitHub API
- Via CLI: `gh workflow list`

---

## 🐛 Troubleshooting

### Workflow fails with "Docker login failed"
- Check that `DOCKER_USERNAME` and `DOCKER_PASSWORD` secrets are set correctly
- Make sure your Docker Hub password is correct

### Workflow fails with "kubectl not found"
- This is normal if you haven't set up Kubernetes yet
- The workflow will skip Kubernetes deployment if `KUBECONFIG` secret is not set

### Tests fail
- Make sure your test scripts work locally first
- The workflows use `continue-on-error: true` for tests, so they won't block deployment

---

## 🎯 Next Steps

1. ✅ Add GitHub secrets
2. ✅ Push a test commit
3. ✅ Watch workflows run
4. ✅ Verify Docker Hub images are updated
5. ✅ (Optional) Set up Kubernetes deployment

---

**Created:** 2025-01-27  
**Status:** Ready for use

