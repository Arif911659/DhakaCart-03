# 🚨 DhakaCart Disaster Recovery Runbook

**Last Updated:** $(date +"%Y-%m-%d")

## 🎯 Purpose

This runbook provides step-by-step procedures for recovering DhakaCart from various disaster scenarios.

---

## 📋 Emergency Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| DevOps Lead | [Name] | [Phone] | [Email] |
| Database Admin | [Name] | [Phone] | [Email] |
| CTO | [Name] | [Phone] | [Email] |
| Cloud Provider Support | AWS/GCP/Azure | [Support Number] | [Support Email] |

---

## 🔴 Disaster Scenarios

### Scenario 1: Complete Database Loss

**Symptoms:**
- Database is inaccessible
- Data corruption detected
- Accidental data deletion

**Impact:** CRITICAL - No transactions possible

**Recovery Steps:**

1. **Assess the Situation** (2 minutes)
   ```bash
   # Check database status
   docker ps | grep postgres
   # or
   kubectl get pods -n dhakacart | grep db
   ```

2. **Stop Application** (1 minute)
   ```bash
   # Docker Compose
   docker-compose stop backend frontend
   
   # Kubernetes
   kubectl scale deployment dhakacart-backend dhakacart-frontend -n dhakacart --replicas=0
   ```

3. **Identify Latest Backup** (1 minute)
   ```bash
   ls -lht /backups/postgres/ | head -5
   ```

4. **Restore Database** (5-15 minutes)
   ```bash
   cd /home/arif/DhakaCart-03/scripts/restore/
   ./restore-postgres.sh /backups/postgres/dhakacart_postgres_YYYYMMDD_HHMMSS.sql.gz
   ```

5. **Verify Data Integrity** (2 minutes)
   ```bash
   # Connect to database
   docker exec -it dhakacart-db psql -U dhakacart -d dhakacart_db
   
   # Run verification queries
   SELECT COUNT(*) FROM products;
   SELECT COUNT(*) FROM orders;
   SELECT MAX(created_at) FROM orders;
   \q
   ```

6. **Restart Application** (2 minutes)
   ```bash
   # Docker Compose
   docker-compose up -d
   
   # Kubernetes
   kubectl scale deployment dhakacart-backend dhakacart-frontend -n dhakacart --replicas=3,2
   ```

7. **Test Application** (3 minutes)
   ```bash
   # Test frontend
   curl http://localhost:3000
   
   # Test backend API
   curl http://localhost:5000/api/products
   curl http://localhost:5000/health
   ```

8. **Monitor Logs** (5 minutes)
   ```bash
   docker-compose logs -f backend
   # or
   kubectl logs -f -l app=dhakacart-backend -n dhakacart
   ```

**Total Recovery Time Objective (RTO):** 30-45 minutes  
**Recovery Point Objective (RPO):** 24 hours (based on backup frequency)

---

### Scenario 2: Complete Infrastructure Failure

**Symptoms:**
- All servers down
- Cloud region outage
- Complete data center failure

**Impact:** CRITICAL - Complete service outage

**Recovery Steps:**

1. **Activate Disaster Recovery Team** (5 minutes)
   - Notify all stakeholders
   - Start incident log
   - Assign roles

2. **Provision New Infrastructure** (20-30 minutes)
   ```bash
   cd /home/arif/DhakaCart-03/terraform/
   
   # Update region/zone if needed
   terraform init
   terraform plan -var="region=us-east-2"  # Different region
   terraform apply -auto-approve
   ```

3. **Deploy Kubernetes Cluster** (10-15 minutes)
   ```bash
   # For AWS EKS
   eksctl create cluster --name dhakacart-dr --region us-east-2
   
   # Update kubectl context
   aws eks update-kubeconfig --name dhakacart-dr --region us-east-2
   ```

4. **Deploy Application** (10 minutes)
   ```bash
   cd /home/arif/DhakaCart-03/k8s/
   kubectl apply -f namespace.yaml
   kubectl apply -f secrets/
   kubectl apply -f configmaps/
   kubectl apply -f volumes/
   kubectl apply -f deployments/
   kubectl apply -f services/
   kubectl apply -f hpa.yaml
   ```

5. **Restore Latest Backups** (15-20 minutes)
   ```bash
   # Download backups from cloud storage
   aws s3 sync s3://dhakacart-backups/latest /backups/
   
   # Restore PostgreSQL
   cd /home/arif/DhakaCart-03/scripts/restore/
   ./restore-postgres.sh /backups/postgres/latest.sql.gz
   
   # Restore Redis
   ./restore-redis.sh /backups/redis/latest.rdb.gz
   ```

6. **Update DNS** (5-10 minutes)
   ```bash
   # Get new load balancer IP
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   
   # Update DNS records to point to new IP
   # dhakacart.com → NEW_LOAD_BALANCER_IP
   ```

7. **Verify Complete System** (10 minutes)
   - Test all endpoints
   - Verify database connectivity
   - Check monitoring dashboards
   - Test user workflows

8. **Post-Recovery Tasks**
   - Document incident
   - Review what went wrong
   - Update disaster recovery plan
   - Schedule post-mortem meeting

**Total RTO:** 2-3 hours  
**RPO:** 24 hours

---

### Scenario 3: Ransomware Attack / Data Corruption

**Symptoms:**
- Encrypted files
- Modified database records
- Suspicious activity in logs

**Impact:** CRITICAL - Data integrity compromised

**Recovery Steps:**

1. **IMMEDIATELY Isolate Affected Systems** (1 minute)
   ```bash
   # Disconnect from network
   docker network disconnect bridge dhakacart-backend
   # or
   kubectl delete svc dhakacart-backend-service -n dhakacart
   ```

2. **Stop All Services** (1 minute)
   ```bash
   docker-compose down
   # or
   kubectl delete namespace dhakacart
   ```

3. **Preserve Evidence** (10 minutes)
   ```bash
   # Take snapshots of volumes
   docker commit dhakacart-db dhakacart-db-evidence
   
   # Copy logs
   docker logs dhakacart-db > /evidence/db-logs-$(date +%Y%m%d).txt
   ```

4. **Identify Last Known Good Backup** (5 minutes)
   ```bash
   # Find backup before attack
   ls -lht /backups/postgres/ | grep "before corruption date"
   ```

5. **Create Clean Environment** (20 minutes)
   ```bash
   # Remove all containers and volumes
   docker-compose down -v
   docker system prune -af
   
   # Or rebuild Kubernetes cluster
   kubectl delete namespace dhakacart
   ```

6. **Restore from Clean Backup** (20 minutes)
   ```bash
   # Deploy fresh instance
   docker-compose up -d
   
   # Restore from backup BEFORE attack
   ./scripts/restore/restore-postgres.sh /backups/postgres/pre_attack_backup.sql.gz
   ```

7. **Security Audit** (60 minutes)
   ```bash
   # Scan for vulnerabilities
   trivy image dhakacart-backend:latest
   trivy image dhakacart-frontend:latest
   
   # Check for backdoors in code
   # Review access logs
   # Change all passwords and keys
   ```

8. **Gradual Restoration** (30 minutes)
   - Restore services one by one
   - Monitor each service carefully
   - Test thoroughly before proceeding

**Total RTO:** 3-4 hours  
**RPO:** Depends on when attack was detected

---

### Scenario 4: Accidental Data Deletion

**Symptoms:**
- User reports missing orders
- Products disappeared
- Data deleted by mistake

**Impact:** HIGH - Partial data loss

**Recovery Steps:**

1. **Stop Further Damage** (30 seconds)
   ```bash
   # Stop backend to prevent more deletions
   docker-compose stop backend
   ```

2. **Assess Scope** (2 minutes)
   ```bash
   # Check what's missing
   docker exec dhakacart-db psql -U dhakacart -d dhakacart_db -c "SELECT COUNT(*) FROM orders;"
   docker exec dhakacart-db psql -U dhakacart -d dhakacart_db -c "SELECT COUNT(*) FROM products;"
   ```

3. **Identify Restoration Point** (3 minutes)
   ```bash
   # Find backup just before deletion
   ls -lht /backups/postgres/ | head -10
   ```

4. **Selective Data Recovery** (10 minutes)
   ```bash
   # Extract specific tables from backup
   gunzip -c /backups/postgres/latest.sql.gz > /tmp/restore.sql
   
   # Restore only affected tables
   grep -A 1000 "CREATE TABLE orders" /tmp/restore.sql | \
     docker exec -i dhakacart-db psql -U dhakacart -d dhakacart_db
   ```

5. **Verify Restoration** (5 minutes)
   ```bash
   # Check data is back
   docker exec dhakacart-db psql -U dhakacart -d dhakacart_db -c "SELECT COUNT(*) FROM orders;"
   docker exec dhakacart-db psql -U dhakacart-d dhakacart_db -c "SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;"
   ```

6. **Restart Application** (1 minute)
   ```bash
   docker-compose start backend
   ```

**Total RTO:** 20-30 minutes  
**RPO:** Hours (depending on backup frequency)

---

### Scenario 5: Critical Kubernetes Pod Failures

**Symptoms:**
- Multiple pods crashing
- CrashLoopBackOff status
- Service unavailable

**Impact:** HIGH - Service degradation

**Recovery Steps:**

1. **Check Pod Status** (1 minute)
   ```bash
   kubectl get pods -n dhakacart
   kubectl describe pod <failing-pod> -n dhakacart
   ```

2. **Check Logs** (2 minutes)
   ```bash
   kubectl logs <pod-name> -n dhakacart
   kubectl logs <pod-name> -n dhakacart --previous
   ```

3. **Quick Fixes to Try** (5 minutes)
   ```bash
   # Restart deployment
   kubectl rollout restart deployment dhakacart-backend -n dhakacart
   
   # Scale down and up
   kubectl scale deployment dhakacart-backend -n dhakacart --replicas=0
   kubectl scale deployment dhakacart-backend -n dhakacart --replicas=3
   
   # Delete failing pods (they'll recreate)
   kubectl delete pod <pod-name> -n dhakacart
   ```

4. **Rollback if Recent Deployment** (2 minutes)
   ```bash
   kubectl rollout undo deployment dhakacart-backend -n dhakacart
   kubectl rollout status deployment dhakacart-backend -n dhakacart
   ```

5. **Check Resources** (2 minutes)
   ```bash
   kubectl top nodes
   kubectl top pods -n dhakacart
   kubectl describe nodes
   ```

6. **If Configuration Issue** (5 minutes)
   ```bash
   # Check ConfigMaps and Secrets
   kubectl get configmap dhakacart-config -n dhakacart -o yaml
   kubectl get secret dhakacart-secrets -n dhakacart -o yaml
   
   # Edit if needed
   kubectl edit configmap dhakacart-config -n dhakacart
   ```

**Total RTO:** 10-20 minutes

---

## 📊 Recovery Time Objectives (RTO)

| Scenario | RTO | Priority |
|----------|-----|----------|
| Database failure | 30-45 min | P0 |
| Complete infrastructure failure | 2-3 hours | P0 |
| Ransomware attack | 3-4 hours | P0 |
| Accidental deletion | 20-30 min | P1 |
| Pod failures | 10-20 min | P1 |

---

## 🔍 Post-Disaster Checklist

After any disaster recovery:

- [ ] Document the incident (what, when, why, how)
- [ ] Verify all services are functioning
- [ ] Check data integrity
- [ ] Review monitoring dashboards
- [ ] Notify stakeholders of resolution
- [ ] Schedule post-mortem meeting
- [ ] Update disaster recovery procedures
- [ ] Test backups from the incident
- [ ] Review and update alerting rules
- [ ] Conduct tabletop exercise based on learnings

---

## 🧪 DR Testing Schedule

- **Monthly:** Test backup restore procedure
- **Quarterly:** Full disaster recovery drill
- **Annually:** Complete infrastructure failover test

---

## 📞 Escalation Path

1. **Level 1:** DevOps Engineer (0-15 min)
2. **Level 2:** DevOps Lead (15-30 min)
3. **Level 3:** CTO + Database Admin (30-60 min)
4. **Level 4:** CEO + Cloud Provider Support (60+ min)

---

## 📚 Related Documents

- [Backup Scripts README](../backup/README.md)
- [Restore Scripts README](../restore/README.md)
- [Kubernetes Deployment Guide](../../k8s/DEPLOYMENT_GUIDE.md)
- [Terraform Infrastructure Guide](../../terraform/README.md)
- [Monitoring Setup](../../monitoring/README.md)

---

**Remember:** In a disaster, stay calm, follow the runbook, and communicate clearly with the team.

**Test your disaster recovery plan regularly!**

