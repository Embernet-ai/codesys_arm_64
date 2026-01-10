#!/bin/bash
# deploy-customer.sh - Deploy CODESYS pod for a customer
#
# Usage: ./deploy-customer.sh <customer-name> [architecture]
# Example: ./deploy-customer.sh acme-corp arm64

set -e

CUSTOMER=$1
ARCH=${2:-arm64}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$CUSTOMER" ]; then
    echo -e "${RED}Error: Customer name required${NC}"
    echo "Usage: $0 <customer-name> [arm64|arm32]"
    echo ""
    echo "Examples:"
    echo "  $0 acme-corp arm64"
    echo "  $0 widget-co arm32"
    exit 1
fi

if [[ "$ARCH" != "arm64" && "$ARCH" != "arm32" ]]; then
    echo -e "${RED}Error: Architecture must be 'arm64' or 'arm32'${NC}"
    exit 1
fi

echo -e "${BLUE}=============================================="
echo "CODESYS Customer Deployment"
echo "=============================================="
echo -e "Customer: ${GREEN}$CUSTOMER${NC}"
echo -e "Architecture: ${GREEN}$ARCH${NC}"
echo -e "==============================================${NC}\n"

# Check if namespace exists
if kubectl get namespace $CUSTOMER &> /dev/null; then
    echo -e "${YELLOW}Warning: Namespace '$CUSTOMER' already exists${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}Creating namespace: $CUSTOMER${NC}"
    kubectl create namespace $CUSTOMER
    kubectl label namespace $CUSTOMER customer=$CUSTOMER
fi

# Check if deployment already exists
if kubectl get deployment codesys-$ARCH -n $CUSTOMER &> /dev/null; then
    echo -e "${YELLOW}Warning: CODESYS $ARCH deployment already exists in $CUSTOMER${NC}"
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete deployment codesys-$ARCH -n $CUSTOMER
        kubectl delete svc codesys-$ARCH -n $CUSTOMER || true
        kubectl delete pvc codesys-$ARCH-data-pvc -n $CUSTOMER || true
    else
        exit 1
    fi
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
K8S_DIR="$SCRIPT_DIR/../k8s"

# Deploy
echo -e "\n${GREEN}Deploying CODESYS $ARCH...${NC}"

echo "  → Creating PVC..."
cat "$K8S_DIR/$ARCH/pvc.yaml" | sed "s/namespace: codesys/namespace: $CUSTOMER/" | kubectl apply -f -

echo "  → Creating Deployment..."
cat "$K8S_DIR/$ARCH/deployment.yaml" | sed "s/namespace: codesys/namespace: $CUSTOMER/" | kubectl apply -f -

echo "  → Creating Service..."
cat "$K8S_DIR/$ARCH/service.yaml" | sed "s/namespace: codesys/namespace: $CUSTOMER/" | kubectl apply -f -

# Wait for deployment
echo -e "\n${YELLOW}Waiting for deployment to be ready...${NC}"
if kubectl wait --for=condition=available --timeout=300s deployment/codesys-$ARCH -n $CUSTOMER; then
    echo -e "${GREEN}✓ Deployment ready!${NC}"
else
    echo -e "${RED}Error: Deployment failed to become ready${NC}"
    echo "Check logs with:"
    echo "  kubectl logs -n $CUSTOMER -l app=codesys"
    exit 1
fi

# Display status
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Deployment Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

kubectl get all -n $CUSTOMER

# Get service details
echo -e "\n${BLUE}Service Endpoints:${NC}"
kubectl get svc codesys-$ARCH -n $CUSTOMER

SERVICE_IP=$(kubectl get svc codesys-$ARCH -n $CUSTOMER -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$SERVICE_IP" ]; then
    SERVICE_IP=$(kubectl get svc codesys-$ARCH -n $CUSTOMER -o jsonpath='{.spec.clusterIP}')
fi

# Success message
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Customer Information:${NC}"
echo "  Customer: $CUSTOMER"
echo "  Namespace: $CUSTOMER"
echo "  Architecture: $ARCH"
echo "  Service IP: $SERVICE_IP"

echo -e "\n${BLUE}Connection Details:${NC}"
echo "  PLC Communication: $SERVICE_IP:1217"
echo "  Web Visualization: http://$SERVICE_IP:8080"
echo "  OPC UA Server: opc.tcp://$SERVICE_IP:4840"

echo -e "\n${BLUE}CODESYS IDE Setup:${NC}"
echo "  1. Open CODESYS IDE"
echo "  2. Scan network or add device manually"
echo "  3. Connect to: $SERVICE_IP:1217"
echo "  4. Activate license in Tools → License Manager"

echo -e "\n${BLUE}Useful Commands:${NC}"
echo "  View logs:"
echo "    kubectl logs -n $CUSTOMER -l app=codesys -f"
echo ""
echo "  Check status:"
echo "    kubectl get pods -n $CUSTOMER"
echo ""
echo "  Port forward (for testing):"
echo "    kubectl port-forward -n $CUSTOMER svc/codesys-$ARCH 1217:1217 8080:8080"
echo ""
echo "  Delete deployment:"
echo "    kubectl delete namespace $CUSTOMER"
echo ""
