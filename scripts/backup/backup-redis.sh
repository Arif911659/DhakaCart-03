#!/bin/bash
# Redis Backup Script for DhakaCart
# Creates RDB snapshots with timestamp

set -e  # Exit on error

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/redis}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="dhakacart_redis_${TIMESTAMP}.rdb"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DhakaCart Redis Backup ===${NC}"
echo "Started at: $(date)"
echo "Backup directory: $BACKUP_DIR"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if Redis is accessible
echo -e "${YELLOW}Checking Redis connection...${NC}"
if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Redis is accessible${NC}"

# Get Redis info
REDIS_VERSION=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" INFO server | grep redis_version | cut -d':' -f2 | tr -d '\r')
REDIS_KEYS=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DBSIZE | cut -d':' -f2 | tr -d ' \r')
echo "  Redis version: $REDIS_VERSION"
echo "  Total keys: $REDIS_KEYS"

# Trigger Redis save
echo -e "${YELLOW}Triggering Redis save...${NC}"
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" BGSAVE

# Wait for save to complete
echo -e "${YELLOW}Waiting for save to complete...${NC}"
SAVE_IN_PROGRESS=1
while [ $SAVE_IN_PROGRESS -eq 1 ]; do
    LAST_SAVE=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" LASTSAVE)
    sleep 2
    NEW_LAST_SAVE=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" LASTSAVE)
    if [ "$NEW_LAST_SAVE" -gt "$LAST_SAVE" ]; then
        SAVE_IN_PROGRESS=0
    fi
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Redis save completed${NC}"

# Copy RDB file from Redis container or data directory
echo -e "${YELLOW}Copying RDB file...${NC}"
if command -v docker &> /dev/null; then
    # If using Docker, copy from container
    REDIS_CONTAINER=$(docker ps --filter "name=redis" --format "{{.Names}}" | head -1)
    if [ -n "$REDIS_CONTAINER" ]; then
        docker cp "$REDIS_CONTAINER:/data/dump.rdb" "$BACKUP_DIR/$BACKUP_FILE"
    else
        # Copy from local Redis data directory
        cp /var/lib/redis/dump.rdb "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null || \
        cp /data/dump.rdb "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null || \
        echo -e "${RED}ERROR: Cannot find Redis RDB file${NC}" && exit 1
    fi
else
    cp /var/lib/redis/dump.rdb "$BACKUP_DIR/$BACKUP_FILE"
fi

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup created successfully${NC}"
    echo "  File: $BACKUP_FILE"
    echo "  Size: $BACKUP_SIZE"
else
    echo -e "${RED}ERROR: Backup failed${NC}"
    exit 1
fi

# Compress backup
echo -e "${YELLOW}Compressing backup...${NC}"
gzip -f "$BACKUP_DIR/$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"
COMPRESSED_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
echo -e "${GREEN}✓ Backup compressed${NC}"
echo "  Compressed size: $COMPRESSED_SIZE"

# Create backup metadata
cat > "$BACKUP_DIR/${BACKUP_FILE}.meta" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "host": "$REDIS_HOST",
  "port": "$REDIS_PORT",
  "redis_version": "$REDIS_VERSION",
  "total_keys": "$REDIS_KEYS",
  "size": "$COMPRESSED_SIZE",
  "file": "$BACKUP_FILE",
  "created_at": "$(date -Iseconds)",
  "backup_type": "rdb_snapshot"
}
EOF

# Clean old backups (older than RETENTION_DAYS)
echo -e "${YELLOW}Cleaning old backups (older than $RETENTION_DAYS days)...${NC}"
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "dhakacart_redis_*.rdb.gz" -mtime +$RETENTION_DAYS)
if [ -n "$OLD_BACKUPS" ]; then
    echo "$OLD_BACKUPS" | while read -r file; do
        echo "  Deleting: $(basename "$file")"
        rm -f "$file" "${file}.meta"
    done
    DELETED_COUNT=$(echo "$OLD_BACKUPS" | wc -l)
    echo -e "${GREEN}✓ Deleted $DELETED_COUNT old backup(s)${NC}"
else
    echo "  No old backups to delete"
fi

# List recent backups
echo -e "${YELLOW}Recent backups:${NC}"
ls -lht "$BACKUP_DIR"/dhakacart_redis_*.rdb.gz | head -5 | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo -e "${GREEN}=== Backup Completed Successfully ===${NC}"
echo "Finished at: $(date)"
echo "Backup file: $BACKUP_DIR/$BACKUP_FILE"

exit 0

