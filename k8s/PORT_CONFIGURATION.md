# Port Configuration Summary

## Frontend Port Configuration

### Issue Fixed
The frontend React application runs on port **3000** (development server), but the deployment was configured for port **80**, causing readiness/liveness probe failures.

### Current Configuration (Fixed)

#### Frontend Deployment (`deployments/frontend-deployment.yaml`)
- **Container Port**: `3000` ✅
- **Liveness Probe Port**: `3000` ✅
- **Readiness Probe Port**: `3000` ✅

#### Frontend Service (`services/services.yaml`)
- **Service Port**: `80` (external) ✅
- **Target Port**: `3000` (forwards to container port) ✅

#### Ingress (`ingress/ingress.yaml`)
- **Service Port Reference**: `80` (references the service port) ✅

### Port Flow
```
Internet → Load Balancer (Port 80) → Service (Port 80) → Target Port (3000) → Container (Port 3000)
```

### Important Notes
1. **Service Port (80)**: This is the external port that other services/ingress use to access the frontend
2. **Target Port (3000)**: This is the internal port that the service forwards to (matches container port)
3. **Container Port (3000)**: This is the actual port the React app listens on inside the container

### Verification Commands
```bash
# Check deployment port
kubectl get deployment dhakacart-frontend -n dhakacart -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'
# Expected: 3000

# Check service ports
kubectl get svc dhakacart-frontend-service -n dhakacart -o jsonpath='{.spec.ports[0]}'
# Expected: map[port:80 protocol:TCP targetPort:3000]

# Check probe ports
kubectl get deployment dhakacart-frontend -n dhakacart -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}'
# Expected: 3000
```

### Port-Forward Command
```bash
# Forward local port 3000 to service port 80
kubectl port-forward -n dhakacart svc/dhakacart-frontend-service 3000:80

# Access at: http://localhost:3000
```

---
**Last Updated**: 2024-11-30
**Status**: ✅ Fixed and Verified
