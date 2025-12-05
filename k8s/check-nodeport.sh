#!/bin/bash

# Check NodePort Service Configuration
# Purpose: Verify why NodePort 30080 is not accessible

set -e

NAMESPACE="dhakacart"
SERVICE_NAME="dhakacart-frontend-service"

echo "=========================================="
echo "NodePort 30080 Diagnostic"
echo "=========================================="
echo ""

echo "1. Service Details:"
echo "----------------------------------------"
kubectl get svc -n $NAMESPACE $SERVICE_NAME -o yaml
echo ""

echo "2. Service Endpoints:"
echo "----------------------------------------"
kubectl get endpoints -n $NAMESPACE $SERVICE_NAME
echo ""

echo "3. Checking if NodePort is listening on nodes:"
echo "----------------------------------------"
echo "Note: NodePort should be accessible from ANY node IP"
echo ""

# Get all node IPs
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
echo "Testing NodePort on all nodes:"
for node_ip in $NODE_IPS; do
    echo -n "  $node_ip:30080 ... "
    timeout 2 curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$node_ip:30080 2>&1 || echo "Connection refused"
done
echo ""

echo "4. Checking kube-proxy:"
echo "----------------------------------------"
kubectl get pods -n kube-system -l k8s-app=kube-proxy 2>/dev/null || echo "kube-proxy pods not found in kube-system"
echo ""

echo "5. Testing from inside cluster:"
echo "----------------------------------------"
kubectl run test-nodeport --rm -i --tty --image=curlimages/curl --restart=Never -- \
  curl -I http://dhakacart-frontend-service.dhakacart.svc.cluster.local 2>&1 || echo "Test failed"
echo ""

echo "6. Checking iptables rules (on a worker node):"
echo "----------------------------------------"
echo "Run this on a worker node:"
echo "  sudo iptables -t nat -L | grep 30080"
echo ""

echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="

