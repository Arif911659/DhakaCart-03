#!/bin/bash

# ============================================
# DhakaCart - Sync k8s files to Master-1
# ============================================
# Simple script to copy k8s folder to Master-1
# Usage: ./sync-k8s-to-master1.sh
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BASTION_IP="13.229.110.212"
MASTER1_IP="10.0.10.253"
SSH_KEY_PATH="terraform/simple-k8s/dhakacart-k8s-key.pem"
REMOTE_USER="ubuntu"

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}Syncing k8s/ folder to Master-1${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Copy to Bastion
echo -e "${YELLOW}Copying to Bastion...${NC}"
scp -r -i "$SSH_KEY_PATH" k8s/ "$REMOTE_USER@$BASTION_IP:/tmp/" > /dev/null 2>&1
echo -e "${GREEN}✅ Copied to Bastion${NC}"

# Copy from Bastion to Master-1
echo -e "${YELLOW}Copying to Master-1...${NC}"
ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "scp -r -i ~/.ssh/dhakacart-k8s-key.pem /tmp/k8s $REMOTE_USER@$MASTER1_IP:~/k8s" > /dev/null 2>&1
echo -e "${GREEN}✅ Copied to Master-1${NC}"

# Cleanup
ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "rm -rf /tmp/k8s" > /dev/null 2>&1

echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ Sync Complete!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps on Master-1:${NC}"
echo "  1. SSH to Master-1"
echo "  2. Run: kubectl apply -f ~/k8s/..."
echo ""

