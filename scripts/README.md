# 🔧 DhakaCart Scripts

Automated backup, restore, and maintenance scripts for DhakaCart.

## 📁 Directory Structure

```
scripts/
├── backup/
│   ├── backup-postgres.sh    # PostgreSQL backup
│   ├── backup-redis.sh        # Redis backup
│   ├── backup-all.sh          # Complete backup
│   └── backup-cron.sh         # Automated backup setup
├── restore/
│   ├── restore-postgres.sh    # PostgreSQL restore
│   ├── restore-redis.sh       # Redis restore
│   └── test-restore.sh        # Test backup integrity
└── disaster-recovery/
    └── dr-runbook.md          # Disaster recovery procedures
```

---

## 🚀 Quick Start

### Run Manual Backup

```bash
# Backup everything
cd /home/arif/DhakaCart-03/scripts/backup/
./backup-all.sh

# Backup only PostgreSQL
./backup-postgres.sh

# Backup only Redis
./backup-redis.sh
```

### Setup Automated Backups

```bash
cd /home/arif/DhakaCart-03/scripts/backup/
./backup-cron.sh
```

This will guide you through setting up daily automated backups.

### Restore from Backup

```bash
cd /home/arif/DhakaCart-03/scripts/restore/

# Restore PostgreSQL (interactive)
./restore-postgres.sh

# Restore from specific file
./restore-postgres.sh /backups/postgres/dhakacart_postgres_20241123_020000.sql.gz

# Restore Redis
./restore-redis.sh
```

### Test Backup Integrity

```bash
cd /home/arif/DhakaCart-03/scripts/restore/
./test-restore.sh
```

---

## ⚙️ Configuration

Set these environment variables before running scripts:

```bash
# Backup Configuration
export BACKUP_DIR="/backups"
export RETENTION_DAYS=30

# PostgreSQL Configuration
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_USER="dhakacart"
export POSTGRES_PASSWORD="dhakacart123"
export POSTGRES_DB="dhakacart_db"

# Redis Configuration
export REDIS_HOST="localhost"
export REDIS_PORT="6379"

# Optional: S3 Backup
export S3_BUCKET="dhakacart-backups"
```

---

## 📋 Backup Scripts

### backup-postgres.sh

Creates compressed PostgreSQL backups with timestamps.

**Features:**
- Compressed SQL dumps (.sql.gz)
- Automatic cleanup of old backups
- Integrity verification
- Metadata generation
- Optional S3 upload

**Usage:**
```bash
./backup-postgres.sh
```

**Output:**
```
/backups/postgres/dhakacart_postgres_20241123_143022.sql.gz
/backups/postgres/dhakacart_postgres_20241123_143022.sql.gz.meta
```

---

### backup-redis.sh

Creates Redis RDB snapshots.

**Features:**
- Triggers BGSAVE
- Copies RDB file
- Compresses backup
- Metadata generation
- Automatic cleanup

**Usage:**
```bash
./backup-redis.sh
```

**Output:**
```
/backups/redis/dhakacart_redis_20241123_143022.rdb.gz
/backups/redis/dhakacart_redis_20241123_143022.rdb.gz.meta
```

---

### backup-all.sh

Complete backup of all components.

**Features:**
- Backs up PostgreSQL
- Backs up Redis
- Backs up docker-compose files
- Backs up Kubernetes configs
- Creates summary report

**Usage:**
```bash
./backup-all.sh
```

---

### backup-cron.sh

Interactive setup for automated backups.

**Features:**
- Installs cron jobs
- Multiple schedule options
- Optional systemd timer
- User-friendly prompts

**Usage:**
```bash
./backup-cron.sh
```

**Schedules Available:**
1. Daily at 2:00 AM (recommended)
2. Every 12 hours
3. Every 6 hours
4. Custom schedule

---

## 🔄 Restore Scripts

### restore-postgres.sh

Restores PostgreSQL database from backup.

**Features:**
- Interactive backup selection
- Safety backup before restore
- Connection verification
- Data integrity checks
- Restore logging

**Usage:**
```bash
# Interactive mode
./restore-postgres.sh

# Direct restore
./restore-postgres.sh /backups/postgres/backup_file.sql.gz
```

**Safety Features:**
- Creates safety backup before restore
- Terminates existing connections
- Can rollback if restore fails
- Verifies data after restore

---

### restore-redis.sh

Restores Redis data from RDB backup.

**Features:**
- Interactive backup selection
- Safety backup creation
- Automatic Redis restart
- Data verification

**Usage:**
```bash
# Interactive mode
./restore-redis.sh

# Direct restore
./restore-redis.sh /backups/redis/backup_file.rdb.gz
```

---

### test-restore.sh

Tests backup integrity without actually restoring.

**Features:**
- Verifies file integrity
- Checks backup age
- Validates backup size
- Tests extraction
- Generates test report

**Usage:**
```bash
./test-restore.sh
```

**Output:**
```
========================================
   DhakaCart Backup Test
========================================
Testing: Backup directory exists
  ✓ PASSED
Testing: PostgreSQL backups exist
  ✓ PASSED
Testing: Redis backups exist
  ✓ PASSED
...
Passed: 10
Failed: 0
✓ All tests passed! Backups are healthy.
```

---

## 📅 Automated Backup Schedule

After running `backup-cron.sh`, backups will run automatically:

**Recommended Schedule:**
- **Daily at 2:00 AM** - Full backup of all components
- **Retention:** 30 days (configurable)
- **Location:** `/backups/`

**Check Cron Jobs:**
```bash
crontab -l
```

**View Backup Logs:**
```bash
tail -f /backups/logs/backup_*.log
```

---

## 🗂️ Backup Storage Structure

```
/backups/
├── postgres/
│   ├── dhakacart_postgres_20241123_020000.sql.gz
│   ├── dhakacart_postgres_20241123_020000.sql.gz.meta
│   ├── dhakacart_postgres_20241122_020000.sql.gz
│   └── ...
├── redis/
│   ├── dhakacart_redis_20241123_020000.rdb.gz
│   ├── dhakacart_redis_20241123_020000.rdb.gz.meta
│   └── ...
├── app/
│   ├── docker-compose_20241123_020000.yml
│   ├── k8s_20241123_020000.tar.gz
│   └── ...
└── logs/
    ├── backup_20241123_020000.log
    └── ...
```

---

## 🔐 Security Best Practices

1. **Encrypt Backups:**
   ```bash
   # Encrypt backup
   gpg --symmetric --cipher-algo AES256 backup_file.sql.gz
   
   # Decrypt backup
   gpg --decrypt backup_file.sql.gz.gpg > backup_file.sql.gz
   ```

2. **Secure Backup Storage:**
   - Use restricted permissions: `chmod 600 /backups/*`
   - Store backups on separate server/storage
   - Use encrypted volumes

3. **Cloud Backup:**
   ```bash
   # Upload to S3 (add to backup scripts)
   aws s3 cp /backups/postgres/ s3://dhakacart-backups/postgres/ --recursive
   
   # Enable S3 versioning
   aws s3api put-bucket-versioning --bucket dhakacart-backups --versioning-configuration Status=Enabled
   ```

4. **Protect Credentials:**
   - Use environment variables
   - Never commit passwords to Git
   - Use secrets management (Vault, AWS Secrets Manager)

---

## 🆘 Emergency Recovery

In case of disaster, follow these steps:

1. **Stop the application**
2. **Identify the latest good backup**
3. **Run restore script**
4. **Verify data integrity**
5. **Restart application**
6. **Monitor closely**

**Full procedure:** See [Disaster Recovery Runbook](disaster-recovery/dr-runbook.md)

---

## 📊 Monitoring Backups

### Check Backup Status

```bash
# List recent backups
ls -lht /backups/postgres/ | head -5
ls -lht /backups/redis/ | head -5

# Check backup sizes
du -sh /backups/*

# View backup metadata
cat /backups/postgres/latest_backup.sql.gz.meta | jq
```

### Backup Monitoring in Grafana

Add these queries to your monitoring dashboard:

```promql
# Backup age (hours since last backup)
time() - file_mtime{path="/backups/postgres/latest.sql.gz"}

# Backup size
file_size_bytes{path="/backups/postgres/latest.sql.gz"}

# Alert if no backup in 26 hours
(time() - file_mtime{path="/backups/postgres/latest.sql.gz"}) > 93600
```

---

## 🧪 Testing Procedures

### Monthly Backup Test

1. Run test-restore.sh
2. Verify all tests pass
3. Check backup age and size
4. Document results

### Quarterly DR Drill

1. Simulate complete failure
2. Restore from backup
3. Verify application works
4. Document time taken
5. Update DR procedures

---

## 🔧 Troubleshooting

### Backup Failed

```bash
# Check disk space
df -h /backups

# Check permissions
ls -la /backups/

# Check database connection
pg_isready -h localhost -p 5432 -U dhakacart
redis-cli -h localhost -p 6379 ping

# View logs
tail -f /backups/logs/backup_*.log
```

### Restore Failed

```bash
# Verify backup file
gunzip -t backup_file.sql.gz

# Check for corruption
md5sum backup_file.sql.gz

# Try different backup
ls -lt /backups/postgres/ | head -10
```

### Cron Not Running

```bash
# Check cron service
systemctl status cron  # or crond

# Check cron logs
grep CRON /var/log/syslog

# Test script manually
cd /home/arif/DhakaCart-03/scripts/backup/
./backup-all.sh
```

---

## 📚 Additional Resources

- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/current/backup.html)
- [Redis Persistence](https://redis.io/docs/management/persistence/)
- [Disaster Recovery Best Practices](https://aws.amazon.com/disaster-recovery/)

---

**💾 Remember: A backup is only as good as your last successful restore test!**

