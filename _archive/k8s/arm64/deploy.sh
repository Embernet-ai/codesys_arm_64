#!/bin/bash

# CODESYS ARM64 Deployment Script for k3s
# This script loads Docker images and deploys CODESYS to k3s

set -e

echo "================================================"
echo "CODESYS ARM64 Deployment to k3s"
echo "================================================"

# Configuration
DOCKER_IMAGE_FILE="${1:-codesys-arm64.tar}"
REGISTRY="localhost:5000"
IMAGE_NAME="codesys-arm64"
IMAGE_TAG="latest"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on ARM64 architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}Warning: Not running on ARM64 architecture (detected: $ARCH)${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check prerequisites
echo -e "\n${GREEN}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker not found${NC}"
    exit 1
fi

# Check if k3s is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${GREEN}Prerequisites OK${NC}"

# Load Docker image
echo -e "\n${GREEN}Loading Docker image from $DOCKER_IMAGE_FILE...${NC}"
if [ ! -f "$DOCKER_IMAGE_FILE" ]; then
    echo -e "${RED}Error: Docker image file not found: $DOCKER_IMAGE_FILE${NC}"
    echo "Please provide the path to your CODESYS ARM64 Docker image as an argument"
    echo "Usage: $0 <path-to-docker-image.tar>"
    exit 1
fi

docker load -i "$DOCKER_IMAGE_FILE"

# Get the actual image name from the loaded image
LOADED_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | head -n 1)
echo -e "${GREEN}Loaded image: $LOADED_IMAGE${NC}"

# Tag and push to local registry (optional, for k3s with local registry)
echo -e "\n${GREEN}Tagging image for local registry...${NC}"
docker tag "$LOADED_IMAGE" "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

# Check if local registry is available
if nc -z localhost 5000 2>/dev/null; then
    echo -e "${GREEN}Pushing to local registry...${NC}"
    docker push "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
else
    echo -e "${YELLOW}Local registry not available. Importing directly to k3s...${NC}"
    # For k3s without registry, import directly
    docker save "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG" | sudo k3s ctr images import -
fi

# Create namespace
echo -e "\n${GREEN}Creating namespace...${NC}"
kubectl apply -f ../namespace.yaml

# Apply Kubernetes manifests
echo -e "\n${GREEN}Applying Kubernetes manifests...${NC}"
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for deployment
echo -e "\n${GREEN}Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/codesys-arm64 -n codesys

# Display status
echo -e "\n${GREEN}Deployment Status:${NC}"
kubectl get all -n codesys -l arch=arm64

echo -e "\n${GREEN}Service Endpoints:${NC}"
kubectl get svc codesys-arm64 -n codesys

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}CODESYS ARM64 deployment completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "To check logs:"
echo "  kubectl logs -n codesys -l app=codesys,arch=arm64 -f"
echo ""
echo "To access the service:"
echo "  kubectl port-forward -n codesys svc/codesys-arm64 1217:1217 8080:8080"
