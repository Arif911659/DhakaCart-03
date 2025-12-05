#!/bin/bash

# Frontend Diagnostic Script
# Purpose: Diagnose why frontend NodePort 30080 is not working

set -e

NAMESPACE="dhakacart"
SERVICE_NAME="dhakacart-frontend-service"
APP_LABEL="app=dhakacart-frontend"

echo "=========================================="
echo "Frontend Diagnostic Report"
echo "Date: $(date)"
echo "=========================================="
echo ""

echo "1. Checking Frontend Pods:"
echo "----------------------------------------"
kubectl get pods -n $NAMESPACE -l $APP_LABEL -o wide
echo ""

echo "2. Checking Frontend Service:"
echo "----------------------------------------"
kubectl get svc -n $NAMESPACE $SERVICE_NAME -o yaml
echo ""

echo "3. Checking Service Endpoints:"
echo "----------------------------------------"
kubectl get endpoints -n $NAMESPACE $SERVICE_NAME
echo ""

echo "4. Getting First Pod Name:"
echo "----------------------------------------"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$POD_NAME" ]; then
    echo "❌ No frontend pods found!"
    exit 1
fi
echo "Pod: $POD_NAME"
echo ""

echo "5. Checking Pod Logs (last 30 lines):"
echo "----------------------------------------"
kubectl logs -n $NAMESPACE $POD_NAME --tail=30
echo ""

echo "6. Checking Processes in Container:"
echo "----------------------------------------"
kubectl exec -n $NAMESPACE $POD_NAME -- ps aux 2>/dev/null || echo "Cannot check processes"
echo ""

echo "7. Checking Listening Ports:"
echo "----------------------------------------"
kubectl exec -n $NAMESPACE $POD_NAME -- netstat -tlnp 2>/dev/null || \
kubectl exec -n $NAMESPACE $POD_NAME -- ss -tlnp 2>/dev/null || \
echo "Cannot check ports (netstat/ss not available)"
echo ""

echo "8. Testing Localhost from Pod:"
echo "----------------------------------------"
kubectl exec -n $NAMESPACE $POD_NAME -- curl -I http://localhost:80 2>&1 || \
kubectl exec -n $NAMESPACE $POD_NAME -- wget -qO- http://localhost:80 2>&1 | head -5 || \
echo "Cannot test localhost"
echo ""

echo "9. Checking Container Image:"
echo "----------------------------------------"
kubectl get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.spec.containers[0].image}'
echo ""
echo ""

echo "10. Checking NodePort on Worker Nodes:"
echo "----------------------------------------"
WORKER_NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
for node in $WORKER_NODES; do
    echo "Testing $node:30080..."
    timeout 2 curl -s -o /dev/null -w "  Status: %{http_code}\n" http://$node:30080 2>&1 || echo "  Connection failed"
done
echo ""

echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="

