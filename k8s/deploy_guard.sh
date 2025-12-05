#!/bin/bash

NAMESPACE="dhakacart"
K8S_DIR="k8s/"
SC_NAME="local-path"

echo "--------------------------------------"
echo " Kubernetes Pre-Check & Auto-Fix Script"
echo "--------------------------------------"

### 1. Namespace check
echo "[1] Checking Namespace..."
if kubectl get ns $NAMESPACE >/dev/null 2>&1; then
    echo "✔ Namespace '$NAMESPACE' exists."
else
    echo "✖ Namespace missing. Creating..."
    kubectl create namespace $NAMESPACE
fi


### 2. StorageClass check
echo "[2] Checking StorageClass..."
if kubectl get storageclass | grep -q "$SC_NAME"; then
    echo "✔ StorageClass '$SC_NAME' found."
else
    echo "✖ StorageClass missing. Installing local-path-provisioner..."
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    sleep 3
fi


### 3. Ensure default StorageClass
echo "[3] Setting '$SC_NAME' as default StorageClass..."
kubectl patch storageclass $SC_NAME \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' >/dev/null 2>&1
echo "✔ Default StorageClass configured."


### 4. Remove stuck PVC finalizers
echo "[4] Checking Terminating PVCs..."
PVC_LIST=$(kubectl get pvc -n $NAMESPACE --no-headers | awk '/Terminating/ {print $1}')

if [ -n "$PVC_LIST" ]; then
    echo "✖ Found PVCs stuck in Terminating state:"
    echo "$PVC_LIST"
    for pvc in $PVC_LIST; do
        echo "→ Fixing PVC: $pvc"
        kubectl get pvc $pvc -n $NAMESPACE -o json \
        | jq 'del(.metadata.finalizers)' \
        | kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/persistentvolumeclaims/$pvc/finalize" -f -
    done
else
    echo "✔ No Terminating PVCs found."
fi


### 5. Final apply
echo "[5] Applying Kubernetes manifests from '$K8S_DIR'..."
kubectl apply -f $K8S_DIR


echo "--------------------------------------"
echo "✔ Deployment Completed Successfully"
echo "--------------------------------------"


##############################################
#  EXTRA: TROUBLESHOOT REPORT & COMMANDS
##############################################

echo ""
echo "📌 AUTOMATED TROUBLESHOOT SUMMARY"
echo "--------------------------------------"

echo ""
echo "🔎 Pods Status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🔎 Services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "🔎 PVC Status:"
kubectl get pvc -n $NAMESPACE

echo ""
echo "🔎 PV Status:"
kubectl get pv

echo ""
echo "🔎 Describe any events:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20

echo ""
echo "🔎 StorageClass:"
kubectl get storageclass

echo ""
echo "🔎 Node Status:"
kubectl get nodes -o wide

echo ""
echo "--------------------------------------"
echo "📌 Recommended Troubleshoot Commands"
echo "--------------------------------------"

echo "👉 Describe a stuck pod:"
echo "   kubectl describe pod <pod-name> -n $NAMESPACE"
echo ""
echo "👉 See logs of a pod:"
echo "   kubectl logs <pod-name> -n $NAMESPACE"
echo ""
echo "👉 Check why PVC is not bound:"
echo "   kubectl describe pvc <pvc-name> -n $NAMESPACE"
echo ""
echo "👉 Check local-path-provisioner:"
echo "   kubectl get pods -n local-path-storage"
echo ""
echo "👉 Restart deployment if needed:"
echo "   kubectl rollout restart deployment <deploy-name> -n $NAMESPACE"
echo ""
echo "👉 Full events:"
echo "   kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp"

echo ""
echo "--------------------------------------"
echo "✔ All checks completed!"
echo "--------------------------------------"
