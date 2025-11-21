# Kubernetes Deployment Guide for DhakaCart

## Prerequisites

1. **Kubernetes Cluster** (Choose one):
   - AWS EKS: `eksctl create cluster --name dhakacart --region us-east-1`
   - GCP GKE: `gcloud container clusters create dhakacart --num-nodes=3`
   - DigitalOcean: Use their UI or `doctl kubernetes cluster create dhakacart`
   - Minikube (local): `minikube start --cpus=4 --memory=8192`

2. **kubectl** installed and configured
3. **Helm** installed (for cert-manager)

---

## Quick Deployment (5 minutes)

### Step 1: Apply All Manifests

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply configurations and secrets
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/

# Create persistent volumes
kubectl apply -f k8s/volumes/

# Deploy applications
kubectl apply -f k8s/deployments/

# Create services
kubectl apply -f k8s/services/

# Apply HPA (auto-scaling)
kubectl apply -f k8s/hpa.yaml

# Apply ingress (optional, requires ingress controller)
# kubectl apply -f k8s/ingress/
```

### Step 2: Wait for Pods to be Ready

```bash
kubectl get pods -n dhakacart -w
```

Expected output:
```
NAME                                  READY   STATUS    RESTARTS   AGE
dhakacart-backend-xxx                 1/1     Running   0          2m
dhakacart-backend-xxx                 1/1     Running   0          2m
dhakacart-backend-xxx                 1/1     Running   0          2m
dhakacart-db-xxx                      1/1     Running   0          3m
dhakacart-frontend-xxx                1/1     Running   0          2m
dhakacart-frontend-xxx                1/1     Running   0          2m
dhakacart-redis-xxx                   1/1     Running   0          3m
```

### Step 3: Test the Application

```bash
# Port-forward frontend
kubectl port-forward -n dhakacart svc/dhakacart-frontend-service 3000:3000

# Port-forward backend
kubectl port-forward -n dhakacart svc/dhakacart-backend-service 5000:5000

# Test
curl http://localhost:5000/health
curl http://localhost:3000
```

---

## Detailed Setup

### 1. Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### 2. Install Cert-Manager (for SSL)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create Let's Encrypt ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### 3. Configure DNS

Point your domain to the LoadBalancer IP:

```bash
# Get LoadBalancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Add DNS A records:
# dhakacart.com → <LoadBalancer-IP>
# www.dhakacart.com → <LoadBalancer-IP>
# api.dhakacart.com → <LoadBalancer-IP>
```

### 4. Apply Ingress

```bash
kubectl apply -f k8s/ingress/ingress.yaml
```

---

## Verification Checklist

### Database

```bash
# Check if database is running
kubectl get pods -n dhakacart -l app=dhakacart-db

# Check logs
kubectl logs -n dhakacart -l app=dhakacart-db

# Connect to database
kubectl exec -it -n dhakacart $(kubectl get pod -n dhakacart -l app=dhakacart-db -o jsonpath='{.items[0].metadata.name}') -- psql -U dhakacart -d dhakacart_db

# Run query
\dt
SELECT COUNT(*) FROM products;
\q
```

### Redis

```bash
# Check if Redis is running
kubectl get pods -n dhakacart -l app=dhakacart-redis

# Test Redis
kubectl exec -it -n dhakacart $(kubectl get pod -n dhakacart -l app=dhakacart-redis -o jsonpath='{.items[0].metadata.name}') -- redis-cli ping
```

### Backend

```bash
# Check backend pods
kubectl get pods -n dhakacart -l app=dhakacart-backend

# Check logs
kubectl logs -n dhakacart -l app=dhakacart-backend --tail=50

# Test health endpoint
kubectl exec -it -n dhakacart $(kubectl get pod -n dhakacart -l app=dhakacart-backend -o jsonpath='{.items[0].metadata.name}') -- curl localhost:5000/health
```

### Frontend

```bash
# Check frontend pods
kubectl get pods -n dhakacart -l app=dhakacart-frontend

# Check logs
kubectl logs -n dhakacart -l app=dhakacart-frontend --tail=50
```

---

## Scaling

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment dhakacart-backend -n dhakacart --replicas=5

# Scale frontend
kubectl scale deployment dhakacart-frontend -n dhakacart --replicas=4
```

### Auto-Scaling (HPA)

Already configured! HPA will automatically scale:
- Backend: 3-10 pods based on CPU/memory
- Frontend: 2-8 pods based on CPU/memory

```bash
# Check HPA status
kubectl get hpa -n dhakacart

# Watch auto-scaling in action
kubectl get hpa -n dhakacart -w
```

---

## Updates & Rollouts

### Update Image

```bash
# Update backend to new version
kubectl set image deployment/dhakacart-backend -n dhakacart backend=arifhossaincse22/dhakacart-backend:v1.0.1

# Update frontend
kubectl set image deployment/dhakacart-frontend -n dhakacart frontend=arifhossaincse22/dhakacart-frontend:v1.0.1
```

### Monitor Rollout

```bash
# Watch rollout status
kubectl rollout status deployment/dhakacart-backend -n dhakacart

# Check rollout history
kubectl rollout history deployment/dhakacart-backend -n dhakacart
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/dhakacart-backend -n dhakacart

# Rollback to specific revision
kubectl rollout undo deployment/dhakacart-backend -n dhakacart --to-revision=2
```

---

## Monitoring

### Resource Usage

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n dhakacart

# Describe deployment
kubectl describe deployment dhakacart-backend -n dhakacart
```

### Events

```bash
# Watch events
kubectl get events -n dhakacart --sort-by='.lastTimestamp'

# Filter by type
kubectl get events -n dhakacart --field-selector type=Warning
```

---

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n dhakacart

# Check logs
kubectl logs <pod-name> -n dhakacart

# Check previous logs (if container restarted)
kubectl logs <pod-name> -n dhakacart --previous
```

### Database Connection Issues

```bash
# Test connection from backend pod
kubectl exec -it -n dhakacart $(kubectl get pod -n dhakacart -l app=dhakacart-backend -o jsonpath='{.items[0].metadata.name}') -- sh

# Inside container
nc -zv dhakacart-db-service 5432
exit
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n dhakacart

# Check endpoints
kubectl get endpoints -n dhakacart

# Describe service
kubectl describe svc dhakacart-backend-service -n dhakacart
```

---

## Cleanup

```bash
# Delete all resources
kubectl delete namespace dhakacart

# Or delete individually
kubectl delete -f k8s/deployments/
kubectl delete -f k8s/services/
kubectl delete -f k8s/volumes/
kubectl delete -f k8s/configmaps/
kubectl delete -f k8s/secrets/
kubectl delete -f k8s/namespace.yaml
```

---

## Production Checklist

Before going to production:

- [ ] Change database password in secrets
- [ ] Configure proper domain names
- [ ] Set up SSL certificates
- [ ] Configure backups (Velero)
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure logging (ELK or Loki)
- [ ] Set up alerts
- [ ] Configure resource limits appropriately
- [ ] Test disaster recovery
- [ ] Set up CI/CD pipeline
- [ ] Load test the application
- [ ] Security scan (Trivy, Snyk)
- [ ] Configure network policies
- [ ] Set up secrets management (Vault)

---

## Next Steps

1. Set up monitoring (Prometheus + Grafana)
2. Configure centralized logging (ELK Stack)
3. Implement CI/CD pipeline
4. Set up automated backups
5. Configure alerting
6. Load testing

---

**Your application is now running on Kubernetes!** 🎉
