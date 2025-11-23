#!/bin/bash
# PostgreSQL Restore Script for DhakaCart
# Restores database from backup file

set -e  # Exit on error

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/postgres}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-dhakacart}"
POSTGRES_DB="${POSTGRES_DB:-dhakacart_db}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DhakaCart PostgreSQL Restore ===${NC}"
echo "Started at: $(date)"
echo ""

# Check if backup file is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Available backups:${NC}"
    ls -lht "$BACKUP_DIR"/dhakacart_postgres_*.sql.gz | head -10 | nl
    echo ""
    read -p "Enter backup file name or number: " INPUT
    
    if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
        # User entered a number
        BACKUP_FILE=$(ls -t "$BACKUP_DIR"/dhakacart_postgres_*.sql.gz | sed -n "${INPUT}p")
    else
        # User entered a filename
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
echo "  Database: $POSTGRES_DB"
echo "  Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo ""

# Warning prompt
echo -e "${RED}WARNING: This will REPLACE all data in $POSTGRES_DB!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Check PostgreSQL connection
echo -e "${YELLOW}Checking PostgreSQL connection...${NC}"
if ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot connect to PostgreSQL${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL is accessible${NC}"

# Create a safety backup before restore
echo -e "${YELLOW}Creating safety backup of current database...${NC}"
SAFETY_BACKUP="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).sql.gz"
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    | gzip > "$SAFETY_BACKUP"
echo -e "${GREEN}✓ Safety backup created: $(basename "$SAFETY_BACKUP")${NC}"

# Terminate existing connections
echo -e "${YELLOW}Terminating existing database connections...${NC}"
PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d postgres \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$POSTGRES_DB' AND pid <> pg_backend_pid();" \
    > /dev/null 2>&1
echo -e "${GREEN}✓ Connections terminated${NC}"

# Restore database
echo -e "${YELLOW}Restoring database...${NC}"
gunzip -c "$BACKUP_FILE" | PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d postgres \
    --set ON_ERROR_STOP=on

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database restored successfully${NC}"
else
    echo -e "${RED}ERROR: Restore failed${NC}"
    echo -e "${YELLOW}Attempting to restore from safety backup...${NC}"
    gunzip -c "$SAFETY_BACKUP" | PGPASSWORD="$POSTGRES_PASSWORD" psql \
        -h "$POSTGRES_HOST" \
        -p "$POSTGRES_PORT" \
        -U "$POSTGRES_USER" \
        -d postgres
    exit 1
fi

# Verify restore
echo -e "${YELLOW}Verifying restored data...${NC}"
TABLE_COUNT=$(PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" | tr -d ' ')

PRODUCT_COUNT=$(PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -t -c "SELECT COUNT(*) FROM products;" 2>/dev/null | tr -d ' ' || echo "0")

echo "  Tables: $TABLE_COUNT"
echo "  Products: $PRODUCT_COUNT"
echo -e "${GREEN}✓ Restore verification complete${NC}"

# Create restore log
RESTORE_LOG="$BACKUP_DIR/restore_log_$(date +%Y%m%d_%H%M%S).json"
cat > "$RESTORE_LOG" <<EOF
{
  "restored_at": "$(date -Iseconds)",
  "backup_file": "$(basename "$BACKUP_FILE")",
  "database": "$POSTGRES_DB",
  "host": "$POSTGRES_HOST",
  "tables": $TABLE_COUNT,
  "products": $PRODUCT_COUNT,
  "safety_backup": "$(basename "$SAFETY_BACKUP")",
  "success": true
}
EOF

echo ""
echo -e "${GREEN}=== Restore Completed Successfully ===${NC}"
echo "Finished at: $(date)"
echo "Restore log: $RESTORE_LOG"
echo "Safety backup: $SAFETY_BACKUP"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Verify application functionality"
echo "  2. Check data integrity"
echo "  3. Remove safety backup if everything is OK:"
echo "     rm $SAFETY_BACKUP"
echo ""

exit 0

