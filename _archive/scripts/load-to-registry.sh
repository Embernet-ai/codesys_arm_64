#!/bin/bash
# load-to-registry.sh - Load CODESYS images from GitHub Releases to k3s local registry
#
# Usage: ./load-to-registry.sh [version]
# Example: ./load-to-registry.sh v1.0.0

set -e

VERSION="${1:-v1.0.0}"
GITHUB_REPO="yourorg/codesys_arm_64"  # UPDATE THIS WITH YOUR GITHUB ORG/REPO
REGISTRY="localhost:5000"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================="
echo "CODESYS Podstore Image Loader"
echo "=============================================="
echo -e "Version: ${GREEN}$VERSION${NC}"
echo -e "Source: GitHub Releases"
echo -e "Target: ${GREEN}$REGISTRY${NC}"
echo -e "==============================================${NC}\n"

# Check prerequisites
echo -e "${GREEN}Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker not found${NC}"
    exit 1
fi

if ! command -v wget &> /dev/null; then
    echo -e "${RED}Error: wget not found${NC}"
    exit 1
fi

# Check registry is accessible
if ! curl -sf http://localhost:5000/v2/_catalog > /dev/null; then
    echo -e "${RED}Error: Cannot access registry at localhost:5000${NC}"
    echo -e "${YELLOW}Make sure registry is running and port-forwarded:${NC}"
    echo "  kubectl port-forward -n kube-system svc/registry 5000:5000"
    exit 1
fi

echo -e "${GREEN}Prerequisites OK${NC}\n"

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}Working directory: $TEMP_DIR${NC}\n"
cd $TEMP_DIR

# Download ARM64 image
echo -e "${GREEN}Downloading ARM64 image from GitHub...${NC}"
ARM64_URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION/codesys-arm64.tar"
echo "URL: $ARM64_URL"

if wget --progress=bar:force "$ARM64_URL" 2>&1 | tail -f -n +6; then
    echo -e "${GREEN}✓ ARM64 image downloaded${NC}\n"
else
    echo -e "${RED}Error: Failed to download ARM64 image${NC}"
    echo "Check if release exists: https://github.com/$GITHUB_REPO/releases/tag/$VERSION"
    rm -rf $TEMP_DIR
    exit 1
fi

# Download ARM32 image
echo -e "${GREEN}Downloading ARM32 image from GitHub...${NC}"
ARM32_URL="https://github.com/$GITHUB_REPO/releases/download/$VERSION/codesys-arm32.tar"
echo "URL: $ARM32_URL"

if wget --progress=bar:force "$ARM32_URL" 2>&1 | tail -f -n +6; then
    echo -e "${GREEN}✓ ARM32 image downloaded${NC}\n"
else
    echo -e "${RED}Error: Failed to download ARM32 image${NC}"
    echo "Check if release exists: https://github.com/$GITHUB_REPO/releases/tag/$VERSION"
    rm -rf $TEMP_DIR
    exit 1
fi

# Process ARM64 image
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Processing ARM64 image...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "Loading image to Docker..."
docker load -i codesys-arm64.tar

# Get the loaded image name (try various methods)
LOADED_ARM64=$(docker images --format "{{.Repository}}:{{.Tag}}" --filter "since=$(docker images -q | tail -1)" | head -n 1)
if [ -z "$LOADED_ARM64" ]; then
    # Fallback: search for codesys in name
    LOADED_ARM64=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i codesys | grep -i arm64 | head -n 1)
fi

echo -e "${GREEN}Loaded: $LOADED_ARM64${NC}"

echo "Tagging for local registry..."
docker tag "$LOADED_ARM64" "$REGISTRY/codesys-arm64:$VERSION"
docker tag "$LOADED_ARM64" "$REGISTRY/codesys-arm64:latest"

echo "Pushing to registry..."
docker push "$REGISTRY/codesys-arm64:$VERSION"
docker push "$REGISTRY/codesys-arm64:latest"

echo -e "${GREEN}✓ ARM64 image pushed to registry${NC}\n"

# Process ARM32 image
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Processing ARM32 image...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "Loading image to Docker..."
docker load -i codesys-arm32.tar

# Get the loaded image name
LOADED_ARM32=$(docker images --format "{{.Repository}}:{{.Tag}}" --filter "since=$(docker images -q | tail -1)" | head -n 1)
if [ -z "$LOADED_ARM32" ]; then
    # Fallback: search for codesys in name, exclude arm64
    LOADED_ARM32=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i codesys | grep -i arm | grep -v arm64 | head -n 1)
fi

echo -e "${GREEN}Loaded: $LOADED_ARM32${NC}"

echo "Tagging for local registry..."
docker tag "$LOADED_ARM32" "$REGISTRY/codesys-arm32:$VERSION"
docker tag "$LOADED_ARM32" "$REGISTRY/codesys-arm32:latest"

echo "Pushing to registry..."
docker push "$REGISTRY/codesys-arm32:$VERSION"
docker push "$REGISTRY/codesys-arm32:latest"

echo -e "${GREEN}✓ ARM32 image pushed to registry${NC}\n"

# Cleanup
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
cd /
rm -rf $TEMP_DIR

# Verify
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Verifying registry contents...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "All images in registry:"
curl -s http://localhost:5000/v2/_catalog | jq .

echo -e "\nARM64 tags:"
curl -s http://localhost:5000/v2/codesys-arm64/tags/list | jq .

echo -e "\nARM32 tags:"
curl -s http://localhost:5000/v2/codesys-arm32/tags/list | jq .

# Success message
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Images loaded successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Available images:${NC}"
echo "  $REGISTRY/codesys-arm64:$VERSION"
echo "  $REGISTRY/codesys-arm64:latest"
echo "  $REGISTRY/codesys-arm32:$VERSION"
echo "  $REGISTRY/codesys-arm32:latest"

echo -e "\n${BLUE}Next steps:${NC}"
echo "  Deploy customers with:"
echo "    ./scripts/deploy-customer.sh <customer-name> arm64"
echo ""
echo "  Or manually:"
echo "    kubectl apply -f k8s/arm64/ -n <customer-namespace>"
echo ""
