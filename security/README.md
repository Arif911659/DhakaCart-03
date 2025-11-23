# 🔐 DhakaCart Security

Comprehensive security hardening for DhakaCart infrastructure.

## 📁 Directory Structure

```
security/
├── scanning/
│   ├── trivy-scan.sh          # Container vulnerability scanning
│   └── dependency-check.sh     # NPM dependency audit
├── network-policies/
│   ├── frontend-policy.yaml    # Frontend network restrictions
│   ├── backend-policy.yaml     # Backend network restrictions
│   └── database-policy.yaml    # Database network restrictions
├── ssl/
│   └── certbot-setup.sh        # SSL/TLS automation
└── README.md
```

---

## 🚀 Quick Start

### Container Security Scanning

```bash
cd /home/arif/DhakaCart-03/security/scanning/

# Scan all container images
./trivy-scan.sh

# Check npm dependencies
./dependency-check.sh
```

### Apply Network Policies (Kubernetes)

```bash
cd /home/arif/DhakaCart-03/security/network-policies/

# Apply all policies
kubectl apply -f frontend-policy.yaml
kubectl apply -f backend-policy.yaml
kubectl apply -f database-policy.yaml

# Verify policies
kubectl get networkpolicies -n dhakacart
```

### Setup SSL/TLS

```bash
cd /home/arif/DhakaCart-03/security/ssl/

# Run setup (requires sudo)
sudo ./certbot-setup.sh
```

---

## 🔍 Container Vulnerability Scanning

### Trivy Scanner

Scans Docker images for known vulnerabilities (CVEs).

**Features:**
- Scans OS packages and application dependencies
- Detects CRITICAL, HIGH, MEDIUM severity issues
- Generates detailed reports
- JSON and text output formats

**Usage:**
```bash
./scanning/trivy-scan.sh
```

**Output:**
```
========================================
   DhakaCart Security Scan (Trivy)
========================================
Scanning: arifhossaincse22/dhakacart-backend:latest
  CRITICAL: 0
  HIGH: 2
  MEDIUM: 5

Reports saved to: /tmp/trivy-reports-20241123_140000/
```

**Report Files:**
- `arifhossaincse22_dhakacart-backend_latest.txt` - Human-readable
- `arifhossaincse22_dhakacart-backend_latest.json` - Machine-readable
- `SUMMARY.txt` - Overall summary

**Integration with CI/CD:**

Add to `.github/workflows/ci.yml`:
```yaml
- name: Run Trivy scan
  run: |
    cd security/scanning
    ./trivy-scan.sh
```

---

### Dependency Vulnerability Audit

Checks npm packages for known vulnerabilities.

**Usage:**
```bash
./scanning/dependency-check.sh
```

**Output:**
```
========================================
   Dependency Security Audit
========================================
Auditing: backend
  CRITICAL: 0
  HIGH: 1
  MODERATE: 3
  LOW: 5

Auditing: frontend
  CRITICAL: 0
  HIGH: 0
  MODERATE: 2
  LOW: 4
```

**Remediation:**
```bash
# Backend
cd backend/
npm audit fix

# Frontend
cd frontend/
npm audit fix

# Force updates (may break things)
npm audit fix --force
```

---

## 🛡️ Network Policies (Kubernetes)

Network policies implement **zero-trust networking** - pods can only communicate with explicitly allowed services.

### Architecture

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │
┌──────▼──────────┐
│  Ingress/LB    │
└──────┬──────────┘
       │
┌──────▼──────────┐     ❌ Blocked
│   Frontend      ├────────────────────┐
└──────┬──────────┘                    │
       │                               │
       │ ✅ Allowed                     │
       │                               │
┌──────▼──────────┐                    │
│   Backend       │◄───────────────────┘
└─┬────────────┬──┘
  │            │
  │ ✅          │ ✅
  │            │
┌─▼────────┐ ┌─▼────────┐
│ Database │ │  Redis   │
└──────────┘ └──────────┘
     │            │
     └─────┬──────┘
           │
        ❌ No Internet
```

### Frontend Policy

**Allows Ingress From:**
- Ingress controller (port 80)
- Pods in same namespace

**Allows Egress To:**
- Backend API (port 5000)
- DNS (port 53)
- HTTPS (port 443)

**Apply:**
```bash
kubectl apply -f network-policies/frontend-policy.yaml
```

---

### Backend Policy

**Allows Ingress From:**
- Frontend pods (port 5000)
- Ingress controller (port 5000)
- Monitoring/Prometheus (port 5000)

**Allows Egress To:**
- PostgreSQL database (port 5432)
- Redis cache (port 6379)
- DNS (port 53)
- HTTPS for external APIs (port 443)

**Apply:**
```bash
kubectl apply -f network-policies/backend-policy.yaml
```

---

### Database Policy (Most Restrictive)

**Allows Ingress From:**
- Backend pods ONLY (port 5432/6379)
- Monitoring exporters

**Allows Egress To:**
- DNS ONLY (port 53)
- No internet access

**Apply:**
```bash
kubectl apply -f network-policies/database-policy.yaml
```

---

### Testing Network Policies

```bash
# Test frontend can reach backend
kubectl exec -it -n dhakacart <frontend-pod> -- curl http://dhakacart-backend-service:5000/health

# Test backend can reach database
kubectl exec -it -n dhakacart <backend-pod> -- nc -zv dhakacart-db-service 5432

# Test database CANNOT reach internet (should fail)
kubectl exec -it -n dhakacart <db-pod> -- curl https://google.com
# Expected: timeout or connection refused

# View applied policies
kubectl get networkpolicies -n dhakacart
kubectl describe networkpolicy dhakacart-backend-policy -n dhakacart
```

---

## 🔒 SSL/TLS Automation

### Let's Encrypt Setup

Automates SSL certificate generation using Certbot.

**Features:**
- Free SSL certificates
- Auto-renewal (90-day certificates)
- Multiple domain support
- Nginx configuration
- A+ SSL rating

**Usage:**
```bash
sudo ./ssl/certbot-setup.sh
```

**Interactive Setup:**
```
Enter your domain name: dhakacart.com
Enter www subdomain? (y/n): y
Enter api subdomain? (y/n): y
Enter your email: admin@dhakacart.com
```

**Certificates Generated For:**
- dhakacart.com
- www.dhakacart.com
- api.dhakacart.com

**Auto-Renewal:**
- Runs twice daily via cron
- Certificates renew 30 days before expiration
- Automatic nginx reload

**Test Renewal:**
```bash
certbot renew --dry-run
```

**Check Certificate Status:**
```bash
certbot certificates
```

---

## 🔑 Secrets Management Best Practices

### Environment Variables

**Don't:**
```yaml
environment:
  - DB_PASSWORD=dhakacart123  # ❌ Hardcoded
```

**Do:**
```yaml
environment:
  - DB_PASSWORD=${DB_PASSWORD}  # ✅ From .env file
```

### Kubernetes Secrets

**Create Secret:**
```bash
kubectl create secret generic dhakacart-secrets \
  --from-literal=DB_PASSWORD='your-secure-password' \
  --from-literal=JWT_SECRET='your-jwt-secret' \
  -n dhakacart
```

**Use in Deployment:**
```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: dhakacart-secrets
        key: DB_PASSWORD
```

### External Secrets (Recommended for Production)

**HashiCorp Vault:**
```bash
# Install Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault

# Store secret
vault kv put secret/dhakacart/db password=secure-password

# Access from Kubernetes
# (requires vault-agent or external-secrets operator)
```

**AWS Secrets Manager:**
```bash
# Store secret
aws secretsmanager create-secret \
  --name dhakacart/db-password \
  --secret-string "secure-password"

# Access from EKS
# (requires IRSA or external-secrets operator)
```

---

## 🔐 Security Checklist

### Application Security

- [ ] Remove hardcoded passwords
- [ ] Use environment variables for secrets
- [ ] Implement input validation
- [ ] Use prepared statements (SQL injection prevention)
- [ ] Implement rate limiting
- [ ] Enable CORS properly
- [ ] Hash passwords (bcrypt, argon2)
- [ ] Implement JWT with short expiration
- [ ] Add CSRF protection
- [ ] Sanitize user inputs

### Container Security

- [ ] Run containers as non-root user
- [ ] Use minimal base images (Alpine, distroless)
- [ ] Scan images regularly
- [ ] Keep base images updated
- [ ] Don't include secrets in images
- [ ] Set resource limits
- [ ] Use read-only filesystems where possible
- [ ] Enable security contexts

### Network Security

- [ ] Apply network policies
- [ ] Use private subnets for databases
- [ ] Enable firewall rules
- [ ] Use VPN for management access
- [ ] Implement DDoS protection
- [ ] Enable SSL/TLS everywhere
- [ ] Use strong TLS ciphers
- [ ] Disable unnecessary ports

### Infrastructure Security

- [ ] Enable audit logging
- [ ] Implement RBAC
- [ ] Use separate accounts per environment
- [ ] Enable MFA for admin access
- [ ] Regular security audits
- [ ] Patch management process
- [ ] Backup encryption
- [ ] Disaster recovery testing

### Monitoring & Compliance

- [ ] Monitor failed login attempts
- [ ] Alert on suspicious activity
- [ ] Log all access attempts
- [ ] Regular vulnerability scans
- [ ] Penetration testing
- [ ] Compliance audits (if required)
- [ ] Incident response plan
- [ ] Security training for team

---

## 🚨 Incident Response

### If Security Breach Detected:

1. **Isolate** - Disconnect affected systems
2. **Assess** - Determine scope and impact
3. **Contain** - Prevent further damage
4. **Eradicate** - Remove threat
5. **Recover** - Restore from clean backups
6. **Document** - Record everything
7. **Review** - Post-mortem and improvements

**Emergency Contacts:**
- DevOps Lead: [phone/email]
- Security Team: [contact]
- Cloud Provider Support: [support number]

---

## 📊 Security Metrics

Track these metrics:

- **Vulnerability Count**: CRITICAL/HIGH/MEDIUM
- **Mean Time to Patch (MTTP)**: How fast vulnerabilities are fixed
- **Failed Login Attempts**: Detect brute force attacks
- **Certificate Expiration**: Days until SSL expires
- **Firewall Blocks**: Network threats blocked
- **Security Scan Frequency**: How often scans run

---

## 🔗 Security Resources

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks/
- **Kubernetes Security**: https://kubernetes.io/docs/concepts/security/
- **Docker Security**: https://docs.docker.com/engine/security/
- **Let's Encrypt**: https://letsencrypt.org/docs/
- **Trivy**: https://aquasecurity.github.io/trivy/

---

**🔒 Security is not a one-time task - it's an ongoing process. Review and update regularly!**

