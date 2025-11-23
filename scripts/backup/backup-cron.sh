#!/bin/bash
# Cron Job Setup for Automated Backups
# Run this script to install automated backup cron jobs

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DhakaCart Backup Automation Setup ===${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Current backup scripts location:${NC}"
echo "  $SCRIPT_DIR"
echo ""

# Make scripts executable
echo -e "${YELLOW}Making backup scripts executable...${NC}"
chmod +x "$SCRIPT_DIR/backup-postgres.sh"
chmod +x "$SCRIPT_DIR/backup-redis.sh"
chmod +x "$SCRIPT_DIR/backup-all.sh"
echo -e "${GREEN}✓ Scripts are now executable${NC}"
echo ""

# Create cron jobs
echo -e "${YELLOW}Backup Schedule Options:${NC}"
echo "1. Daily at 2:00 AM (recommended)"
echo "2. Every 12 hours"
echo "3. Every 6 hours"
echo "4. Custom schedule"
echo ""

read -p "Choose option (1-4): " SCHEDULE_OPTION

case $SCHEDULE_OPTION in
    1)
        CRON_SCHEDULE="0 2 * * *"  # Daily at 2 AM
        DESCRIPTION="Daily at 2:00 AM"
        ;;
    2)
        CRON_SCHEDULE="0 */12 * * *"  # Every 12 hours
        DESCRIPTION="Every 12 hours"
        ;;
    3)
        CRON_SCHEDULE="0 */6 * * *"  # Every 6 hours
        DESCRIPTION="Every 6 hours"
        ;;
    4)
        echo ""
        echo "Enter cron schedule (e.g., '0 2 * * *' for 2 AM daily):"
        read -p "Schedule: " CRON_SCHEDULE
        DESCRIPTION="Custom: $CRON_SCHEDULE"
        ;;
    *)
        echo "Invalid option. Using default: Daily at 2 AM"
        CRON_SCHEDULE="0 2 * * *"
        DESCRIPTION="Daily at 2:00 AM"
        ;;
esac

echo ""
echo -e "${YELLOW}Setting up automated backups...${NC}"
echo "  Schedule: $DESCRIPTION"
echo "  Cron: $CRON_SCHEDULE"
echo ""

# Create cron job entry
CRON_JOB="$CRON_SCHEDULE cd $SCRIPT_DIR && ./backup-all.sh"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "backup-all.sh"; then
    echo -e "${YELLOW}Backup cron job already exists. Updating...${NC}"
    # Remove old job
    crontab -l 2>/dev/null | grep -v "backup-all.sh" | crontab -
fi

# Add new cron job
(crontab -l 2>/dev/null; echo "# DhakaCart Automated Backup - $DESCRIPTION"; echo "$CRON_JOB") | crontab -

echo -e "${GREEN}✓ Automated backup cron job installed${NC}"
echo ""

# Show current cron jobs
echo -e "${YELLOW}Current cron jobs:${NC}"
crontab -l | grep -A 1 "DhakaCart"
echo ""

# Create systemd timer alternative (for systems using systemd)
echo -e "${YELLOW}Would you like to create a systemd timer as well? (y/n)${NC}"
read -p "Answer: " CREATE_SYSTEMD

if [ "$CREATE_SYSTEMD" = "y" ]; then
    echo ""
    echo -e "${YELLOW}Creating systemd service and timer...${NC}"
    
    # Create service file
    sudo cat > /etc/systemd/system/dhakacart-backup.service <<EOF
[Unit]
Description=DhakaCart Backup Service
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/backup-all.sh
User=$USER
StandardOutput=journal
StandardError=journal
EOF

    # Create timer file
    sudo cat > /etc/systemd/system/dhakacart-backup.timer <<EOF
[Unit]
Description=DhakaCart Backup Timer
Requires=dhakacart-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Enable and start timer
    sudo systemctl daemon-reload
    sudo systemctl enable dhakacart-backup.timer
    sudo systemctl start dhakacart-backup.timer
    
    echo -e "${GREEN}✓ Systemd timer created and enabled${NC}"
    echo ""
    echo "Check timer status: sudo systemctl status dhakacart-backup.timer"
    echo "Check service logs: sudo journalctl -u dhakacart-backup.service"
fi

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Backup automation is now configured!"
echo ""
echo "Useful commands:"
echo "  View cron jobs:       crontab -l"
echo "  Edit cron jobs:       crontab -e"
echo "  Remove cron job:      crontab -l | grep -v 'backup-all.sh' | crontab -"
echo "  Manual backup:        $SCRIPT_DIR/backup-all.sh"
echo "  Test backup:          $SCRIPT_DIR/backup-postgres.sh"
echo ""

exit 0

