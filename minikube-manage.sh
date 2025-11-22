#!/bin/bash
# DhakaCart Minikube Management Script

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}DhakaCart Minikube Management${NC}"
echo "================================"
echo ""

# Function to check Minikube status
check_status() {
    echo -e "${YELLOW}Checking Minikube status...${NC}"
    minikube status
    echo ""
    echo -e "${YELLOW}Checking pods status...${NC}"
    kubectl get pods -n dhakacart
    echo ""
    echo -e "${YELLOW}Checking services...${NC}"
    kubectl get services -n dhakacart
}

# Function to start services
start_services() {
    echo -e "${GREEN}Starting Minikube...${NC}"
    minikube start
    echo ""
    echo -e "${GREEN}Waiting for pods to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=dhakacart-backend -n dhakacart --timeout=120s
    kubectl wait --for=condition=ready pod -l app=dhakacart-frontend -n dhakacart --timeout=120s
    echo ""
    echo -e "${GREEN}Opening frontend service...${NC}"
    minikube service dhakacart-frontend-service -n dhakacart &
    echo ""
    echo -e "${GREEN}Opening backend service...${NC}"
    minikube service dhakacart-backend-service -n dhakacart &
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}Stopping Minikube...${NC}"
    minikube stop
}

# Function to view logs
view_logs() {
    echo "Select component to view logs:"
    echo "1) Backend"
    echo "2) Frontend"
    echo "3) Database"
    echo "4) Redis"
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1) kubectl logs -f -n dhakacart -l app=dhakacart-backend ;;
        2) kubectl logs -f -n dhakacart -l app=dhakacart-frontend ;;
        3) kubectl logs -f -n dhakacart -l app=dhakacart-db ;;
        4) kubectl logs -f -n dhakacart -l app=dhakacart-redis ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
}

# Function to redeploy
redeploy() {
    echo -e "${YELLOW}Redeploying application...${NC}"
    kubectl delete namespace dhakacart
    sleep 5
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/secrets/
    kubectl apply -f k8s/configmaps/
    kubectl apply -f k8s/volumes/
    kubectl apply -f k8s/deployments/
    kubectl apply -f k8s/services/
    
    # Patch services to NodePort
    kubectl patch service dhakacart-frontend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'
    kubectl patch service dhakacart-backend-service -n dhakacart -p '{"spec":{"type":"NodePort"}}'
    
    echo -e "${GREEN}Deployment complete!${NC}"
}

# Main menu
case "$1" in
    status)
        check_status
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    logs)
        view_logs
        ;;
    redeploy)
        redeploy
        ;;
    *)
        echo "Usage: $0 {status|start|stop|logs|redeploy}"
        echo ""
        echo "Commands:"
        echo "  status    - Check status of Minikube and pods"
        echo "  start     - Start Minikube and open services"
        echo "  stop      - Stop Minikube"
        echo "  logs      - View logs for a specific component"
        echo "  redeploy  - Redeploy the entire application"
        exit 1
        ;;
esac
