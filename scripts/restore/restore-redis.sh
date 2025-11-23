#!/bin/bash
# Redis Restore Script for DhakaCart
# Restores Redis data from RDB backup

set -e  # Exit on error

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/redis}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_DATA_DIR="${REDIS_DATA_DIR:-/var/lib/redis}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DhakaCart Redis Restore ===${NC}"
echo "Started at: $(date)"
echo ""

# Check if backup file is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Available backups:${NC}"
    ls -lht "$BACKUP_DIR"/dhakacart_redis_*.rdb.gz | head -10 | nl
    echo ""
    read -p "Enter backup file name or number: " INPUT
    
    if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
        BACKUP_FILE=$(ls -t "$BACKUP_DIR"/dhakacart_redis_*.rdb.gz | sed -n "${INPUT}p")
    else
        BACKUP_FILE="$BACKUP_DIR/$INPUT"
    fi
else
    BACKUP_FILE="$1"
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}ERROR: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Restore Configuration:${NC}"
echo "  Backup file: $(basename "$BACKUP_FILE")"
echo "  Redis: $REDIS_HOST:$REDIS_PORT"
echo ""

# Warning prompt
echo -e "${RED}WARNING: This will REPLACE all data in Redis!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Check Redis connection
echo -e "${YELLOW}Checking Redis connection...${NC}"
if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot connect to Redis${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Redis is accessible${NC}"

# Get current key count for safety backup
CURRENT_KEYS=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DBSIZE | cut -d':' -f2 | tr -d ' \r')
echo "  Current keys: $CURRENT_KEYS"

# Create safety backup
if [ "$CURRENT_KEYS" -gt 0 ]; then
    echo -e "${YELLOW}Creating safety backup...${NC}"
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" BGSAVE
    sleep 3
    SAFETY_BACKUP="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).rdb.gz"
    
    if command -v docker &> /dev/null; then
        REDIS_CONTAINER=$(docker ps --filter "name=redis" --format "{{.Names}}" | head -1)
        if [ -n "$REDIS_CONTAINER" ]; then
            docker cp "$REDIS_CONTAINER:/data/dump.rdb" /tmp/safety_dump.rdb
            gzip -c /tmp/safety_dump.rdb > "$SAFETY_BACKUP"
            rm /tmp/safety_dump.rdb
        fi
    fi
    echo -e "${GREEN}✓ Safety backup created${NC}"
fi

# Stop Redis (method depends on how Redis is running)
echo -e "${YELLOW}Stopping Redis...${NC}"
if command -v docker &> /dev/null; then
    REDIS_CONTAINER=$(docker ps --filter "name=redis" --format "{{.Names}}" | head -1)
    if [ -n "$REDIS_CONTAINER" ]; then
        docker stop "$REDIS_CONTAINER"
        RESTART_COMMAND="docker start $REDIS_CONTAINER"
    fi
elif command -v systemctl &> /dev/null; then
    sudo systemctl stop redis
    RESTART_COMMAND="sudo systemctl start redis"
else
    sudo service redis-server stop
    RESTART_COMMAND="sudo service redis-server start"
fi
echo -e "${GREEN}✓ Redis stopped${NC}"

# Decompress and copy backup file
echo -e "${YELLOW}Restoring RDB file...${NC}"
gunzip -c "$BACKUP_FILE" > /tmp/dump.rdb

if command -v docker &> /dev/null && [ -n "$REDIS_CONTAINER" ]; then
    # Docker: copy to volume
    docker cp /tmp/dump.rdb "$REDIS_CONTAINER:/data/dump.rdb"
else
    # Direct file system
    sudo cp /tmp/dump.rdb "$REDIS_DATA_DIR/dump.rdb"
    sudo chown redis:redis "$REDIS_DATA_DIR/dump.rdb" 2>/dev/null || true
fi

rm /tmp/dump.rdb
echo -e "${GREEN}✓ RDB file copied${NC}"

# Start Redis
echo -e "${YELLOW}Starting Redis...${NC}"
eval "$RESTART_COMMAND"
sleep 3
echo -e "${GREEN}✓ Redis started${NC}"

# Verify restore
echo -e "${YELLOW}Verifying restored data...${NC}"
RETRIES=0
while [ $RETRIES -lt 10 ]; do
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
        break
    fi
    sleep 1
    RETRIES=$((RETRIES + 1))
done

RESTORED_KEYS=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DBSIZE | cut -d':' -f2 | tr -d ' \r')
echo "  Restored keys: $RESTORED_KEYS"
echo -e "${GREEN}✓ Restore verification complete${NC}"

# Create restore log
RESTORE_LOG="$BACKUP_DIR/restore_log_$(date +%Y%m%d_%H%M%S).json"
cat > "$RESTORE_LOG" <<EOF
{
  "restored_at": "$(date -Iseconds)",
  "backup_file": "$(basename "$BACKUP_FILE")",
  "host": "$REDIS_HOST",
  "port": "$REDIS_PORT",
  "keys_before": $CURRENT_KEYS,
  "keys_after": $RESTORED_KEYS,
  "success": true
}
EOF

echo ""
echo -e "${GREEN}=== Restore Completed Successfully ===${NC}"
echo "Finished at: $(date)"
echo "Restore log: $RESTORE_LOG"
echo ""

exit 0

