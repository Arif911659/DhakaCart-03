#!/bin/bash

# ============================================
# DhakaCart - Copy k8s folder to Master-1
# ============================================
# This script copies the k8s/ folder from your local machine to Master-1 node
# Usage: ./copy-k8s-to-master1.sh
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (from aws_instances_output.txt)
BASTION_IP="13.229.110.212"
MASTER1_IP="10.0.10.253"
SSH_KEY_PATH="terraform/simple-k8s/dhakacart-k8s-key.pem"
K8S_FOLDER="k8s"
REMOTE_USER="ubuntu"

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}DhakaCart - Copy k8s folder to Master-1${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Step 1: Check if we're in the right directory
echo -e "${YELLOW}[Step 1] Checking current directory...${NC}"
if [ ! -d "$K8S_FOLDER" ]; then
    echo -e "${RED}❌ Error: k8s/ folder not found in current directory!${NC}"
    echo -e "${YELLOW}Please run this script from /home/arif/DhakaCart-03/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ k8s/ folder found${NC}"
echo ""

# Step 2: Check if SSH key exists
echo -e "${YELLOW}[Step 2] Checking SSH key...${NC}"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ Error: SSH key not found at: $SSH_KEY_PATH${NC}"
    echo -e "${YELLOW}Please check the path and try again${NC}"
    exit 1
fi

# Set correct permissions for SSH key
chmod 400 "$SSH_KEY_PATH" 2>/dev/null || true
echo -e "${GREEN}✅ SSH key found: $SSH_KEY_PATH${NC}"
echo ""

# Step 3: Test Bastion connection
echo -e "${YELLOW}[Step 3] Testing connection to Bastion ($BASTION_IP)...${NC}"
if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$REMOTE_USER@$BASTION_IP" "echo 'Connection successful'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to Bastion ($BASTION_IP)${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "  1. Internet connection"
    echo -e "  2. Bastion IP is correct: $BASTION_IP"
    echo -e "  3. SSH key path is correct: $SSH_KEY_PATH"
    exit 1
fi
echo -e "${GREEN}✅ Bastion connection successful${NC}"
echo ""

# Step 4: Copy SSH key to Bastion (if not already there)
echo -e "${YELLOW}[Step 4] Ensuring SSH key is on Bastion...${NC}"
if ! ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "test -f ~/.ssh/dhakacart-k8s-key.pem" > /dev/null 2>&1; then
    echo -e "${YELLOW}Copying SSH key to Bastion...${NC}"
    ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh" > /dev/null 2>&1
    scp -i "$SSH_KEY_PATH" "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP:~/.ssh/dhakacart-k8s-key.pem" > /dev/null 2>&1
    ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "chmod 400 ~/.ssh/dhakacart-k8s-key.pem" > /dev/null 2>&1
    echo -e "${GREEN}✅ SSH key copied to Bastion${NC}"
else
    echo -e "${GREEN}✅ SSH key already exists on Bastion${NC}"
fi
echo ""

# Step 5: Test Master-1 connection from Bastion
echo -e "${YELLOW}[Step 5] Testing connection to Master-1 ($MASTER1_IP)...${NC}"
if ! ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "ssh -i ~/.ssh/dhakacart-k8s-key.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no $REMOTE_USER@$MASTER1_IP 'echo Connection successful'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to Master-1 ($MASTER1_IP) from Bastion${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "  1. Master-1 IP is correct: $MASTER1_IP"
    echo -e "  2. Master-1 is running"
    exit 1
fi
echo -e "${GREEN}✅ Master-1 connection successful${NC}"
echo ""

# Step 6: Copy k8s folder to Bastion first
echo -e "${YELLOW}[Step 6] Copying k8s/ folder to Bastion...${NC}"
echo -e "${BLUE}This may take a few minutes depending on file size...${NC}"

# Remove old k8s folder on Bastion if exists
ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "rm -rf /tmp/k8s" > /dev/null 2>&1 || true

# Copy k8s folder to Bastion
if scp -r -i "$SSH_KEY_PATH" "$K8S_FOLDER" "$REMOTE_USER@$BASTION_IP:/tmp/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ k8s/ folder copied to Bastion${NC}"
else
    echo -e "${RED}❌ Error: Failed to copy k8s/ folder to Bastion${NC}"
    exit 1
fi
echo ""

# Step 7: Copy k8s folder from Bastion to Master-1
echo -e "${YELLOW}[Step 7] Copying k8s/ folder from Bastion to Master-1...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"

# Remove old k8s folder on Master-1 if exists
ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "ssh -i ~/.ssh/dhakacart-k8s-key.pem $REMOTE_USER@$MASTER1_IP 'rm -rf ~/k8s'" > /dev/null 2>&1 || true

# Copy k8s folder from Bastion to Master-1
if ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "scp -r -i ~/.ssh/dhakacart-k8s-key.pem /tmp/k8s $REMOTE_USER@$MASTER1_IP:~/k8s" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ k8s/ folder copied to Master-1${NC}"
else
    echo -e "${RED}❌ Error: Failed to copy k8s/ folder to Master-1${NC}"
    exit 1
fi
echo ""

# Step 8: Verify files on Master-1
echo -e "${YELLOW}[Step 8] Verifying files on Master-1...${NC}"
FILE_COUNT=$(ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "ssh -i ~/.ssh/dhakacart-k8s-key.pem $REMOTE_USER@$MASTER1_IP 'find ~/k8s -type f | wc -l'" 2>/dev/null || echo "0")

if [ "$FILE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Files verified on Master-1 (Total: $FILE_COUNT files)${NC}"
    
    # Show some key files
    echo -e "${BLUE}Key files found:${NC}"
    ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "ssh -i ~/.ssh/dhakacart-k8s-key.pem $REMOTE_USER@$MASTER1_IP 'ls -la ~/k8s/ | head -20'" 2>/dev/null || true
else
    echo -e "${RED}❌ Error: No files found on Master-1${NC}"
    exit 1
fi
echo ""

# Step 9: Cleanup temporary files on Bastion
echo -e "${YELLOW}[Step 9] Cleaning up temporary files...${NC}"
ssh -i "$SSH_KEY_PATH" "$REMOTE_USER@$BASTION_IP" "rm -rf /tmp/k8s" > /dev/null 2>&1 || true
echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

# Success message
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ SUCCESS! k8s/ folder copied to Master-1${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. SSH to Master-1:"
echo -e "   ${YELLOW}ssh -i $SSH_KEY_PATH $REMOTE_USER@$BASTION_IP${NC}"
echo -e "   ${YELLOW}ssh -i ~/.ssh/dhakacart-k8s-key.pem $REMOTE_USER@$MASTER1_IP${NC}"
echo ""
echo -e "2. Verify files:"
echo -e "   ${YELLOW}ls -la ~/k8s/${NC}"
echo ""
echo -e "3. Deploy application:"
echo -e "   ${YELLOW}kubectl apply -f ~/k8s/namespace.yaml${NC}"
echo -e "   ${YELLOW}kubectl apply -f ~/k8s/secrets/${NC}"
echo -e "   ${YELLOW}kubectl apply -f ~/k8s/configmaps/${NC}"
echo -e "   ${YELLOW}kubectl apply -f ~/k8s/volumes/${NC}"
echo -e "   ${YELLOW}kubectl apply -f ~/k8s/deployments/${NC}"
echo -e "   ${YELLOW}kubectl apply -f ~/k8s/services/${NC}"
echo ""
echo -e "${GREEN}Good luck! 🚀${NC}"

