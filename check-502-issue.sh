#!/bin/bash
# Quick diagnostic script for 502 Bad Gateway issue

echo "=== 502 Bad Gateway Diagnostic ==="
echo ""

echo "1. Frontend Service Type and NodePort:"
kubectl get svc -n dhakacart dhakacart-frontend-service -o wide
echo ""

echo "2. NodePort Number:"
NODEPORT=$(kubectl get svc -n dhakacart dhakacart-frontend-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -z "$NODEPORT" ]; then
    echo "❌ ERROR: Service is not NodePort type!"
    echo "   Fix: kubectl patch svc dhakacart-frontend-service -n dhakacart -p '{\"spec\":{\"type\":\"NodePort\"}}'"
else
    echo "✅ NodePort: $NODEPORT"
fi
echo ""

echo "3. Frontend Pods Status:"
kubectl get pods -n dhakacart -l app=dhakacart-frontend
echo ""

echo "4. Service Endpoints:"
kubectl get endpoints -n dhakacart dhakacart-frontend-service
echo ""

if [ ! -z "$NODEPORT" ]; then
    echo "5. Testing NodePort on Worker Nodes:"
    echo "   Worker-1 (10.0.10.170:$NODEPORT):"
    curl -I -s -m 5 http://10.0.10.170:$NODEPORT 2>&1 | head -3 || echo "   ❌ Connection failed"
    echo ""
    echo "   Worker-2 (10.0.10.12:$NODEPORT):"
    curl -I -s -m 5 http://10.0.10.12:$NODEPORT 2>&1 | head -3 || echo "   ❌ Connection failed"
    echo ""
    echo "   Worker-3 (10.0.10.84:$NODEPORT):"
    curl -I -s -m 5 http://10.0.10.84:$NODEPORT 2>&1 | head -3 || echo "   ❌ Connection failed"
    echo ""
fi

echo "6. Frontend Pod Logs (last 10 lines):"
kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=10 2>/dev/null | tail -5 || echo "   No logs available"
echo ""

echo "=== Next Steps ==="
echo "1. Check AWS Console → Target Groups → Health status"
echo "2. Verify target group port matches NodePort: $NODEPORT"
echo "3. Check security groups allow port $NODEPORT"
echo "4. Verify Load Balancer listener is configured"
