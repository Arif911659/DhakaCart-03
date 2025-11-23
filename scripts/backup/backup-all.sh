#!/bin/bash
# Complete Backup Script for DhakaCart
# Backs up PostgreSQL, Redis, and application files

set -e  # Exit on error

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${BACKUP_ROOT}/logs/backup_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory
mkdir -p "${BACKUP_ROOT}/logs"

# Log function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log "${BLUE}========================================${NC}"
log "${BLUE}   DhakaCart Complete Backup${NC}"
log "${BLUE}========================================${NC}"
log "Started at: $(date)"
log "Backup root: $BACKUP_ROOT"
log ""

# Track success/failure
BACKUP_SUCCESS=true

# 1. Backup PostgreSQL
log "${YELLOW}[1/3] Backing up PostgreSQL database...${NC}"
if bash "$(dirname "$0")/backup-postgres.sh" >> "$LOG_FILE" 2>&1; then
    log "${GREEN}✓ PostgreSQL backup completed${NC}"
else
    log "${RED}✗ PostgreSQL backup failed${NC}"
    BACKUP_SUCCESS=false
fi
log ""

# 2. Backup Redis
log "${YELLOW}[2/3] Backing up Redis cache...${NC}"
if bash "$(dirname "$0")/backup-redis.sh" >> "$LOG_FILE" 2>&1; then
    log "${GREEN}✓ Redis backup completed${NC}"
else
    log "${RED}✗ Redis backup failed${NC}"
    BACKUP_SUCCESS=false
fi
log ""

# 3. Backup application files (optional)
log "${YELLOW}[3/3] Backing up application files...${NC}"
APP_BACKUP_DIR="${BACKUP_ROOT}/app"
mkdir -p "$APP_BACKUP_DIR"

# Backup docker-compose files
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml "$APP_BACKUP_DIR/docker-compose_${TIMESTAMP}.yml"
    log "  ✓ Saved docker-compose.yml"
fi

if [ -f "docker-compose.prod.yml" ]; then
    cp docker-compose.prod.yml "$APP_BACKUP_DIR/docker-compose.prod_${TIMESTAMP}.yml"
    log "  ✓ Saved docker-compose.prod.yml"
fi

# Backup environment files (if they exist and are not ignored)
if [ -f ".env" ]; then
    cp .env "$APP_BACKUP_DIR/env_${TIMESTAMP}.txt"
    log "  ✓ Saved environment file"
fi

# Backup k8s configurations
if [ -d "k8s" ]; then
    tar -czf "$APP_BACKUP_DIR/k8s_${TIMESTAMP}.tar.gz" k8s/
    log "  ✓ Saved Kubernetes configurations"
fi

log "${GREEN}✓ Application files backup completed${NC}"
log ""

# Create backup summary
SUMMARY_FILE="${BACKUP_ROOT}/backup_summary_${TIMESTAMP}.json"
cat > "$SUMMARY_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "date": "$(date -Iseconds)",
  "backup_root": "$BACKUP_ROOT",
  "components": {
    "postgres": $([ -f "${BACKUP_ROOT}/postgres/dhakacart_postgres_${TIMESTAMP}.sql.gz" ] && echo "true" || echo "false"),
    "redis": $([ -f "${BACKUP_ROOT}/redis/dhakacart_redis_${TIMESTAMP}.rdb.gz" ] && echo "true" || echo "false"),
    "application": true
  },
  "success": $([ "$BACKUP_SUCCESS" = true ] && echo "true" || echo "false"),
  "log_file": "$LOG_FILE"
}
EOF

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_ROOT" | cut -f1)

log "${BLUE}========================================${NC}"
if [ "$BACKUP_SUCCESS" = true ]; then
    log "${GREEN}✓ Complete Backup Successful${NC}"
else
    log "${RED}✗ Backup Completed with Errors${NC}"
fi
log "${BLUE}========================================${NC}"
log "Finished at: $(date)"
log "Total backup size: $TOTAL_SIZE"
log "Summary: $SUMMARY_FILE"
log "Log file: $LOG_FILE"
log ""

# Send notification (configure email/webhook)
if [ "$BACKUP_SUCCESS" = true ]; then
    # Success notification
    if command -v mail &> /dev/null && [ -n "$ADMIN_EMAIL" ]; then
        echo "Complete backup completed successfully. Size: $TOTAL_SIZE" | \
        mail -s "[DhakaCart] Backup Success - $(date +%Y-%m-%d)" "$ADMIN_EMAIL"
    fi
    exit 0
else
    # Failure notification
    if command -v mail &> /dev/null && [ -n "$ADMIN_EMAIL" ]; then
        cat "$LOG_FILE" | \
        mail -s "[DhakaCart] BACKUP FAILED - $(date +%Y-%m-%d)" "$ADMIN_EMAIL"
    fi
    exit 1
fi

