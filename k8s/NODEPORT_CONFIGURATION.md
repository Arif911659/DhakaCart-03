# NodePort Configuration - Fixed Port

## ✅ Fixed NodePort: 30080

The frontend service now uses a **fixed/predefined NodePort** instead of a random port.

---

## Configuration

### Frontend Service (`services/services.yaml`)

```yaml
spec:
  type: NodePort
  ports:
  - port: 80              # Service port (internal)
    targetPort: 3000      # Container port (React app)
    nodePort: 30080        # Fixed NodePort (external access)
    protocol: TCP
```

### Port Flow

```
Internet (Port 80)
    ↓
Load Balancer (Port 80)
    ↓
Worker Node (Port 30080) ← FIXED NodePort
    ↓
Service (Port 80) → Target Port (3000)
    ↓
Container (Port 3000) ← React App
```

---

## NodePort Range

- **Valid Range**: 30000 - 32767
- **Selected**: 30080 (commonly used for web services)
- **Why 30080**: Easy to remember, within valid range, not conflicting with common ports

---

## Benefits of Fixed NodePort

1. ✅ **Predictable**: Always the same port (30080)
2. ✅ **Easy Configuration**: AWS Load Balancer configured once
3. ✅ **No Random Ports**: Don't need to check NodePort every time
4. ✅ **Documentation**: Can document the exact port

---

## AWS Load Balancer Configuration

### Target Group Settings

- **Port**: `30080` (Fixed - always the same)
- **Protocol**: TCP
- **Health Check**: HTTP on port 30080, path: `/`

### Worker Nodes to Register

- worker-1: `10.0.10.170:30080`
- worker-2: `10.0.10.12:30080`
- worker-3: `10.0.10.84:30080`

---

## Security Group Rules

### Worker Nodes Security Group

**Inbound Rule:**
- Type: Custom TCP
- Port: `30080`
- Source: Load Balancer Security Group (or 0.0.0.0/0 for testing)
- Description: "Allow NodePort 30080 from Load Balancer"

---

## Verification

### Check NodePort

```bash
kubectl get svc -n dhakacart dhakacart-frontend-service
```

**Expected Output:**
```
NAME                        TYPE       PORT(S)
dhakacart-frontend-service  NodePort   80:30080/TCP
```

### Test NodePort Directly

```bash
# From Master-1 or Bastion
curl http://10.0.10.170:30080  # Worker-1
curl http://10.0.10.12:30080   # Worker-2
curl http://10.0.10.84:30080   # Worker-3
```

---

## Applying the Fixed NodePort

### Master-1 এ Apply করুন:

```bash
# Apply updated service
kubectl apply -f ~/k8s/services/services.yaml

# Verify NodePort
kubectl get svc -n dhakacart dhakacart-frontend-service

# Expected: 80:30080/TCP
```

---

## Changing the NodePort

If you want to use a different port (within 30000-32767):

```yaml
ports:
- port: 80
  targetPort: 3000
  nodePort: 30100  # Change to your preferred port
  protocol: TCP
```

**Common Choices:**
- `30080` - Web services (current)
- `30100` - Alternative
- `30200` - Alternative
- `30300` - Alternative

---

## Important Notes

1. **Port Range**: NodePort must be between 30000-32767
2. **Port Conflicts**: Make sure the port is not used by other services
3. **Security**: Expose NodePort only through Load Balancer, not directly to internet
4. **Load Balancer**: Configure once with port 30080, no need to change

---

## Troubleshooting

### If NodePort Not Working

1. **Check Service:**
   ```bash
   kubectl get svc -n dhakacart dhakacart-frontend-service
   ```

2. **Check Pods:**
   ```bash
   kubectl get pods -n dhakacart -l app=dhakacart-frontend
   ```

3. **Test Directly:**
   ```bash
   curl http://<worker-ip>:30080
   ```

4. **Check Security Group:**
   - Port 30080 allowed in inbound rules

---

**Last Updated**: 2024-11-30  
**NodePort**: 30080 (Fixed)  
**Status**: ✅ Configured

