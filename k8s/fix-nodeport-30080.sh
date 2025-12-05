#!/bin/bash

# Fix NodePort 30080 Issue
# Purpose: Recreate service and verify NodePort is working

set -e

NAMESPACE="dhakacart"
SERVICE_NAME="dhakacart-frontend-service"
SERVICE_FILE="services/services.yaml"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Fixing NodePort 30080 Issue${NC}"
echo ""

# Step 1: Check current service
echo -e "${GREEN}Step 1: Checking current service...${NC}"
kubectl get svc -n $NAMESPACE $SERVICE_NAME -o yaml | grep -A 5 "nodePort\|type\|targetPort" || echo "Service not found"
echo ""

# Step 2: Check endpoints
echo -e "${GREEN}Step 2: Checking service endpoints...${NC}"
ENDPOINTS=$(kubectl get endpoints -n $NAMESPACE $SERVICE_NAME -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || echo "")
if [ -z "$ENDPOINTS" ]; then
    echo -e "${RED}❌ No endpoints found! Service selector might not match pods.${NC}"
else
    echo -e "${GREEN}✅ Endpoints found: $ENDPOINTS${NC}"
fi
echo ""

# Step 3: Delete and recreate service
echo -e "${GREEN}Step 3: Recreating service...${NC}"
kubectl delete svc $SERVICE_NAME -n $NAMESPACE 2>/dev/null || echo "Service doesn't exist, will create new"
sleep 2

# Extract only frontend service from yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
  namespace: $NAMESPACE
  labels:
    app: dhakacart-frontend
spec:
  type: NodePort
  selector:
    app: dhakacart-frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
    protocol: TCP
    name: http
EOF

echo -e "${GREEN}✅ Service recreated${NC}"
echo ""

# Step 4: Wait and verify
echo -e "${GREEN}Step 4: Waiting for service to be ready...${NC}"
sleep 5

# Step 5: Verify service
echo -e "${GREEN}Step 5: Verifying service...${NC}"
kubectl get svc -n $NAMESPACE $SERVICE_NAME

NODEPORT=$(kubectl get svc -n $NAMESPACE $SERVICE_NAME -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
if [ "$NODEPORT" = "30080" ]; then
    echo -e "${GREEN}✅ NodePort is correct: $NODEPORT${NC}"
else
    echo -e "${RED}❌ NodePort mismatch: $NODEPORT (expected 30080)${NC}"
fi
echo ""

# Step 6: Check endpoints again
echo -e "${GREEN}Step 6: Checking endpoints after recreation...${NC}"
kubectl get endpoints -n $NAMESPACE $SERVICE_NAME
echo ""

# Step 7: Test from inside cluster
echo -e "${GREEN}Step 7: Testing service from inside cluster...${NC}"
kubectl run test-frontend-svc --rm -i --tty --image=curlimages/curl --restart=Never -- \
  curl -I http://${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local 2>&1 || echo "Test failed"
echo ""

# Step 8: Get node IPs for testing
echo -e "${GREEN}Step 8: Node IPs for NodePort testing:${NC}"
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
echo ""
echo -e "${YELLOW}Test NodePort with:${NC}"
echo "  curl http://<node-ip>:30080"
echo ""

echo -e "${GREEN}✅ Service recreation complete!${NC}"
echo ""
echo "If NodePort still doesn't work, check:"
echo "  1. kube-proxy pods: kubectl get pods -n kube-system -l k8s-app=kube-proxy"
echo "  2. Security groups allow port 30080"
echo "  3. ALB target group configuration"
echo ""

