#!/bin/bash
# PostgreSQL Backup Script for DhakaCart
# Creates compressed backups with timestamp

set -e  # Exit on error

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/postgres}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-dhakacart}"
POSTGRES_DB="${POSTGRES_DB:-dhakacart_db}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="dhakacart_postgres_${TIMESTAMP}.sql.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DhakaCart PostgreSQL Backup ===${NC}"
echo "Started at: $(date)"
echo "Backup directory: $BACKUP_DIR"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if PostgreSQL is accessible
echo -e "${YELLOW}Checking PostgreSQL connection...${NC}"
if ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot connect to PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL is accessible${NC}"

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    --clean \
    --if-exists \
    --create \
    --format=plain \
    | gzip > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup created successfully${NC}"
    echo "  File: $BACKUP_FILE"
    echo "  Size: $BACKUP_SIZE"
else
    echo -e "${RED}ERROR: Backup failed${NC}"
    exit 1
fi

# Verify backup
echo -e "${YELLOW}Verifying backup integrity...${NC}"
if gunzip -t "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Backup file is valid${NC}"
else
    echo -e "${RED}ERROR: Backup file is corrupted${NC}"
    exit 1
fi

# Create backup metadata
cat > "$BACKUP_DIR/${BACKUP_FILE}.meta" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "database": "$POSTGRES_DB",
  "host": "$POSTGRES_HOST",
  "size": "$BACKUP_SIZE",
  "file": "$BACKUP_FILE",
  "created_at": "$(date -Iseconds)",
  "backup_type": "full"
}
EOF

# Clean old backups (older than RETENTION_DAYS)
echo -e "${YELLOW}Cleaning old backups (older than $RETENTION_DAYS days)...${NC}"
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "dhakacart_postgres_*.sql.gz" -mtime +$RETENTION_DAYS)
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
ls -lht "$BACKUP_DIR"/dhakacart_postgres_*.sql.gz | head -5 | awk '{print "  " $9 " (" $5 ")"}'

# Optional: Upload to cloud storage (uncomment if using AWS S3)
# if [ -n "$S3_BUCKET" ]; then
#     echo -e "${YELLOW}Uploading to S3...${NC}"
#     aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/backups/postgres/" \
#         --storage-class STANDARD_IA
#     if [ $? -eq 0 ]; then
#         echo -e "${GREEN}✓ Uploaded to S3${NC}"
#     else
#         echo -e "${RED}ERROR: S3 upload failed${NC}"
#     fi
# fi

# Send notification (optional - configure email settings)
# if command -v mail &> /dev/null; then
#     echo "PostgreSQL backup completed successfully" | \
#     mail -s "[DhakaCart] Backup Success: $BACKUP_FILE" admin@dhakacart.com
# fi

echo ""
echo -e "${GREEN}=== Backup Completed Successfully ===${NC}"
echo "Finished at: $(date)"
echo "Backup file: $BACKUP_DIR/$BACKUP_FILE"

exit 0

