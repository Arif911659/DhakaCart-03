#!/bin/bash
# Test Restore Script for DhakaCart
# Verifies backup integrity by testing restore process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   DhakaCart Backup Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Started at: $(date)"
echo ""

BACKUP_DIR="${BACKUP_DIR:-/backups}"
TEST_REPORT="/tmp/backup_test_$(date +%Y%m%d_%H%M%S).txt"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    if eval "$test_command" >> "$TEST_REPORT" 2>&1; then
        echo -e "${GREEN}  ✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Check backup directory exists
run_test "Backup directory exists" "[ -d '$BACKUP_DIR' ]"

# Test 2: Check PostgreSQL backups exist
run_test "PostgreSQL backups exist" "[ $(find '$BACKUP_DIR/postgres' -name '*.sql.gz' 2>/dev/null | wc -l) -gt 0 ]"

# Test 3: Check Redis backups exist
run_test "Redis backups exist" "[ $(find '$BACKUP_DIR/redis' -name '*.rdb.gz' 2>/dev/null | wc -l) -gt 0 ]"

# Test 4: Verify latest PostgreSQL backup integrity
if [ -d "$BACKUP_DIR/postgres" ]; then
    LATEST_PG=$(ls -t "$BACKUP_DIR"/postgres/dhakacart_postgres_*.sql.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_PG" ]; then
        run_test "PostgreSQL backup integrity" "gunzip -t '$LATEST_PG'"
        
        # Test 5: Verify SQL content
        run_test "PostgreSQL backup has valid SQL" "gunzip -c '$LATEST_PG' | head -20 | grep -q 'PostgreSQL'"
    fi
fi

# Test 6: Verify latest Redis backup integrity
if [ -d "$BACKUP_DIR/redis" ]; then
    LATEST_REDIS=$(ls -t "$BACKUP_DIR"/redis/dhakacart_redis_*.rdb.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_REDIS" ]; then
        run_test "Redis backup integrity" "gunzip -t '$LATEST_REDIS'"
    fi
fi

# Test 7: Check backup age (warn if > 2 days old)
if [ -n "$LATEST_PG" ]; then
    BACKUP_AGE=$((($(date +%s) - $(stat -f %m "$LATEST_PG" 2>/dev/null || stat -c %Y "$LATEST_PG")) / 86400))
    if [ $BACKUP_AGE -lt 2 ]; then
        run_test "Backup freshness" "true"
        echo "    Backup age: $BACKUP_AGE days"
    else
        run_test "Backup freshness" "false"
        echo -e "    ${YELLOW}Warning: Backup is $BACKUP_AGE days old${NC}"
    fi
fi

# Test 8: Check backup size (warn if too small)
if [ -n "$LATEST_PG" ]; then
    BACKUP_SIZE=$(stat -f %z "$LATEST_PG" 2>/dev/null || stat -c %s "$LATEST_PG")
    MIN_SIZE=$((1024 * 100))  # 100 KB minimum
    if [ $BACKUP_SIZE -gt $MIN_SIZE ]; then
        run_test "Backup size reasonable" "true"
        echo "    Size: $(du -h "$LATEST_PG" | cut -f1)"
    else
        run_test "Backup size reasonable" "false"
        echo -e "    ${RED}Warning: Backup seems too small${NC}"
    fi
fi

# Test 9: Check disk space
DISK_USAGE=$(df "$BACKUP_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
if [ $DISK_USAGE -lt 90 ]; then
    run_test "Sufficient disk space" "true"
    echo "    Usage: $DISK_USAGE%"
else
    run_test "Sufficient disk space" "false"
    echo -e "    ${RED}Warning: Disk usage at $DISK_USAGE%${NC}"
fi

# Test 10: Test PostgreSQL restore (dry-run if possible)
if [ -n "$LATEST_PG" ] && command -v pg_restore &> /dev/null; then
    echo -e "${YELLOW}Testing PostgreSQL restore (simulation)...${NC}"
    TMP_SQL="/tmp/test_restore.sql"
    gunzip -c "$LATEST_PG" > "$TMP_SQL"
    if [ -s "$TMP_SQL" ] && grep -q "CREATE" "$TMP_SQL"; then
        echo -e "${GREEN}  ✓ PASSED${NC}"
        echo "    SQL file can be extracted and contains DDL"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}  ✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    rm -f "$TMP_SQL"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Backups are healthy.${NC}"
    echo ""
    echo "Latest backups:"
    [ -n "$LATEST_PG" ] && echo "  PostgreSQL: $(basename "$LATEST_PG") ($(du -h "$LATEST_PG" | cut -f1))"
    [ -n "$LATEST_REDIS" ] && echo "  Redis: $(basename "$LATEST_REDIS") ($(du -h "$LATEST_REDIS" | cut -f1))"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review backups.${NC}"
    echo ""
    echo "Test report: $TEST_REPORT"
    exit 1
fi

