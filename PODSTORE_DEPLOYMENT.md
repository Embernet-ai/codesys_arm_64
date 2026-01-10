# Podstore Deployment Guide
## GitHub Releases → k3s Local Registry → Multi-Tenant Customer Pods

*The definitive guide for managing your CODESYS podstore*

---

## Overview

This guide covers the complete workflow for managing CODESYS container images in your multi-tenant k3s cluster:

```
CODESYS Store (download once)
    ↓
GitHub Releases (version control & distribution)
    ↓
k3s Local Registry (localhost:5000)
    ↓
Customer Pods (fast deployment from local cache)
```

**Benefits:**
- ✅ Single source of truth (GitHub Releases)
- ✅ Fast customer deployments (no external downloads)
- ✅ Version control and rollback capability
- ✅ No bandwidth costs per deployment
- ✅ Works offline once images are cached

---

## Part 1: Initial Setup (One-Time)

### 1.1: Set Up k3s Local Registry

Your k3s cluster needs a local container registry to cache images.

**Check if registry already exists:**
```bash
kubectl get svc -n kube-system registry
```

**If not found, create it:**

```bash
# Create registry deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: kube-system
  labels:
    app: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: registry-data
          mountPath: /var/lib/registry
        env:
        - name: REGISTRY_STORAGE_DELETE_ENABLED
          value: "true"
      volumes:
      - name: registry-data
        hostPath:
          path: /var/lib/rancher/k3s/registry
          type: DirectoryOrCreate
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: kube-system
spec:
  selector:
    app: registry
  type: ClusterIP
  ports:
  - name: registry
    port: 5000
    targetPort: 5000
EOF
```

**Verify registry is running:**
```bash
kubectl get pods -n kube-system -l app=registry
# Should show: registry-xxxxxxxxxx-xxxxx   1/1     Running
```

**Port forward for local access (run in separate terminal):**
```bash
kubectl port-forward -n kube-system svc/registry 5000:5000
```

Or set up as a service that's always accessible:
```bash
# Add to /etc/hosts on your deployment machine
echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts
```

### 1.2: Verify Docker Access to Registry

```bash
# Test registry access
curl http://localhost:5000/v2/_catalog

# Should return: {"repositories":[]}
```

---

## Part 2: Publishing Images (Per Version)

### 2.1: Download from CODESYS Store

1. Go to [CODESYS Store](https://store.codesys.com/en/codesys-control-for-linux-arm-sl-1.html)
2. Download both ARM variants:
   - CODESYS Control for Linux ARM64 SL
   - CODESYS Control for Linux ARM SL (32-bit)
3. Save as `.tar` files

```bash
# Create workspace
mkdir -p ~/codesys-release
cd ~/codesys-release

# Move downloaded files
mv ~/Downloads/CODESYS_Control_*.tar.gz .

# Extract if needed (depends on CODESYS packaging)
# The .tar files should be Docker images
```

### 2.2: Upload to GitHub Releases

```bash
# Navigate to your repo
cd ~/codesys_arm_64

# Create a new version tag
VERSION="v1.0.0"
git tag -a $VERSION -m "CODESYS Control for Linux ARM SL $VERSION"
git push origin $VERSION
```

**Then manually upload via GitHub UI:**

1. Go to: `https://github.com/<your-org>/codesys_arm_64/releases`
2. Click "Draft a new release"
3. Select your tag (v1.0.0)
4. Upload files:
   - `codesys-arm64.tar` (ARM64 image)
   - `codesys-arm32.tar` (ARM32 image)
5. Add release notes:
   ```markdown
   ## CODESYS Control for Linux ARM SL v1.0.0
   
   ### Images Included
   - ARM64 (ARMv8): `codesys-arm64.tar`
   - ARM32 (ARMv7): `codesys-arm32.tar`
   
   ### Source
   Downloaded from: https://store.codesys.com/en/codesys-control-for-linux-arm-sl-1.html
   
   ### Installation
   See [PODSTORE_DEPLOYMENT.md](PODSTORE_DEPLOYMENT.md)
   
   ### License Requirements
   Each deployment requires a valid CODESYS license.
   Contact your SI for licensing.
   ```
6. Click "Publish release"

### 2.3: Load Images into k3s Local Registry

**Automated Script** (recommended):

Save this as `scripts/load-to-registry.sh`:

```bash
#!/bin/bash
# load-to-registry.sh - Load CODESYS images from GitHub to k3s registry

set -e

VERSION="${1:-v1.0.0}"
GITHUB_REPO="yourorg/codesys_arm_64"  # UPDATE THIS
REGISTRY="localhost:5000"

echo "=============================================="
echo "Loading CODESYS $VERSION to k3s registry"
echo "=============================================="

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Download from GitHub releases
echo "Downloading ARM64 image..."
wget "https://github.com/$GITHUB_REPO/releases/download/$VERSION/codesys-arm64.tar"

echo "Downloading ARM32 image..."
wget "https://github.com/$GITHUB_REPO/releases/download/$VERSION/codesys-arm32.tar"

# Load ARM64
echo ""
echo "Loading ARM64 image to Docker..."
docker load -i codesys-arm64.tar

LOADED_ARM64=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i codesys | grep -i arm64 | head -n 1)
echo "Loaded: $LOADED_ARM64"

echo "Tagging for local registry..."
docker tag "$LOADED_ARM64" "$REGISTRY/codesys-arm64:$VERSION"
docker tag "$LOADED_ARM64" "$REGISTRY/codesys-arm64:latest"

echo "Pushing to registry..."
docker push "$REGISTRY/codesys-arm64:$VERSION"
docker push "$REGISTRY/codesys-arm64:latest"

# Load ARM32
echo ""
echo "Loading ARM32 image to Docker..."
docker load -i codesys-arm32.tar

LOADED_ARM32=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i codesys | grep -i arm | grep -v arm64 | head -n 1)
echo "Loaded: $LOADED_ARM32"

echo "Tagging for local registry..."
docker tag "$LOADED_ARM32" "$REGISTRY/codesys-arm32:$VERSION"
docker tag "$LOADED_ARM32" "$REGISTRY/codesys-arm32:latest"

echo "Pushing to registry..."
docker push "$REGISTRY/codesys-arm32:$VERSION"
docker push "$REGISTRY/codesys-arm32:latest"

# Cleanup
cd /
rm -rf $TEMP_DIR

echo ""
echo "=============================================="
echo "✓ Images loaded successfully!"
echo "=============================================="
echo ""
echo "Verify with:"
echo "  curl http://localhost:5000/v2/_catalog"
echo ""
echo "Available images:"
echo "  $REGISTRY/codesys-arm64:$VERSION"
echo "  $REGISTRY/codesys-arm64:latest"
echo "  $REGISTRY/codesys-arm32:$VERSION"
echo "  $REGISTRY/codesys-arm32:latest"
```

**Make executable and run:**

```bash
chmod +x scripts/load-to-registry.sh
./scripts/load-to-registry.sh v1.0.0
```

**Manual Method:**

```bash
# Download from GitHub
VERSION="v1.0.0"
wget "https://github.com/yourorg/codesys_arm_64/releases/download/$VERSION/codesys-arm64.tar"
wget "https://github.com/yourorg/codesys_arm_64/releases/download/$VERSION/codesys-arm32.tar"

# Load into Docker
docker load -i codesys-arm64.tar
docker load -i codesys-arm32.tar

# Tag for registry (get actual image name from docker images)
LOADED_IMAGE=$(docker images | grep codesys | grep arm64 | awk '{print $1":"$2}')
docker tag $LOADED_IMAGE localhost:5000/codesys-arm64:v1.0.0
docker tag $LOADED_IMAGE localhost:5000/codesys-arm64:latest

# Push to registry
docker push localhost:5000/codesys-arm64:v1.0.0
docker push localhost:5000/codesys-arm64:latest

# Repeat for ARM32
LOADED_IMAGE=$(docker images | grep codesys | grep -v arm64 | awk '{print $1":"$2}')
docker tag $LOADED_IMAGE localhost:5000/codesys-arm32:v1.0.0
docker tag $LOADED_IMAGE localhost:5000/codesys-arm32:latest

docker push localhost:5000/codesys-arm32:v1.0.0
docker push localhost:5000/codesys-arm32:latest
```

### 2.4: Verify Images in Registry

```bash
# List all images in registry
curl http://localhost:5000/v2/_catalog

# Check specific image tags
curl http://localhost:5000/v2/codesys-arm64/tags/list
curl http://localhost:5000/v2/codesys-arm32/tags/list
```

Expected output:
```json
{"name":"codesys-arm64","tags":["v1.0.0","latest"]}
{"name":"codesys-arm32","tags":["v1.0.0","latest"]}
```

---

## Part 3: Deploying Customer Pods

### 3.1: Deploy New Customer

The deployment manifests are already configured to pull from `localhost:5000`.

```bash
# Create customer namespace
CUSTOMER="acme-corp"
kubectl create namespace $CUSTOMER
kubectl label namespace $CUSTOMER customer=$CUSTOMER

# Deploy CODESYS (ARM64 example)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/arm64/pvc.yaml -n $CUSTOMER
kubectl apply -f k8s/arm64/deployment.yaml -n $CUSTOMER
kubectl apply -f k8s/arm64/service.yaml -n $CUSTOMER

# Verify
kubectl get pods -n $CUSTOMER
```

**The deployment will pull from `localhost:5000/codesys-arm64:latest`** ✓

### 3.2: Deploy Multiple Customers (Automated)

Save as `scripts/deploy-customer.sh`:

```bash
#!/bin/bash
# deploy-customer.sh - Deploy CODESYS for a customer

CUSTOMER=$1
ARCH=${2:-arm64}

if [ -z "$CUSTOMER" ]; then
    echo "Usage: $0 <customer-name> [arm64|arm32]"
    exit 1
fi

echo "Deploying CODESYS $ARCH for customer: $CUSTOMER"

# Create namespace
kubectl create namespace $CUSTOMER 2>/dev/null || true
kubectl label namespace $CUSTOMER customer=$CUSTOMER --overwrite

# Deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/$ARCH/pvc.yaml -n $CUSTOMER
kubectl apply -f k8s/$ARCH/deployment.yaml -n $CUSTOMER
kubectl apply -f k8s/$ARCH/service.yaml -n $CUSTOMER

# Wait for ready
kubectl wait --for=condition=available --timeout=300s deployment/codesys-$ARCH -n $CUSTOMER

echo "✓ Deployment complete for $CUSTOMER"
kubectl get all -n $CUSTOMER
```

**Usage:**
```bash
chmod +x scripts/deploy-customer.sh

./scripts/deploy-customer.sh acme-corp arm64
./scripts/deploy-customer.sh widget-co arm64
./scripts/deploy-customer.sh legacy-inc arm32
```

### 3.3: Monitor All Customer Deployments

```bash
# List all customer namespaces
kubectl get ns -l customer

# Check all CODESYS pods
kubectl get pods -A -l app=codesys

# View resource usage
kubectl top pods -A -l app=codesys
```

---

## Part 4: Updating Images

### 4.1: New Version Release

When CODESYS releases updates:

```bash
# 1. Download new images from CODESYS Store
# 2. Upload to GitHub as new release (v1.1.0)
# 3. Load to registry

./scripts/load-to-registry.sh v1.1.0
```

### 4.2: Update Customer Deployments

**Option A: Update to specific version**

```bash
# Update image tag in deployment
kubectl set image deployment/codesys-arm64 \
  codesys-runtime=localhost:5000/codesys-arm64:v1.1.0 \
  -n acme-corp

# Rolling restart
kubectl rollout status deployment/codesys-arm64 -n acme-corp
```

**Option B: Update to latest**

```bash
# If using :latest tag, force pull
kubectl rollout restart deployment/codesys-arm64 -n acme-corp
```

**Option C: Update all customers at once**

```bash
for ns in $(kubectl get ns -l customer --no-headers -o custom-columns=":metadata.name"); do
    echo "Updating $ns..."
    kubectl rollout restart deployment/codesys-arm64 -n $ns 2>/dev/null || true
    kubectl rollout restart deployment/codesys-arm32 -n $ns 2>/dev/null || true
done
```

---

## Part 5: Management & Maintenance

### 5.1: Registry Maintenance

**View registry disk usage:**
```bash
kubectl exec -n kube-system deploy/registry -- du -sh /var/lib/registry
```

**Clean up old images:**
```bash
# Delete specific tag
curl -X DELETE http://localhost:5000/v2/codesys-arm64/manifests/<tag>

# Run garbage collection
kubectl exec -n kube-system deploy/registry -- \
  registry garbage-collect /etc/docker/registry/config.yml
```

### 5.2: Backup Registry

```bash
# Backup registry data
kubectl exec -n kube-system deploy/registry -- \
  tar czf - /var/lib/registry > registry-backup-$(date +%Y%m%d).tar.gz

# Restore
cat registry-backup-20260110.tar.gz | \
  kubectl exec -i -n kube-system deploy/registry -- \
  tar xzf - -C /
```

### 5.3: Customer Tracking

Maintain a customer registry (spreadsheet/database):

| Customer | Namespace | Architecture | Image Version | Deployed Date | License | Status |
|----------|-----------|--------------|---------------|---------------|---------|--------|
| Acme Corp | acme-corp | arm64 | v1.0.0 | 2026-01-10 | XXXX-XXXX | Active |
| Widget Co | widget-co | arm64 | v1.0.0 | 2026-01-11 | YYYY-YYYY | Active |

---

## Part 6: Troubleshooting

### Image Pull Failures

```bash
# Check if registry is accessible
curl http://localhost:5000/v2/_catalog

# Check if image exists
curl http://localhost:5000/v2/codesys-arm64/tags/list

# Describe pod for errors
kubectl describe pod -n <customer> <pod-name>

# Common fixes:
# - Restart port-forward: kubectl port-forward -n kube-system svc/registry 5000:5000
# - Re-push image to registry
# - Check imagePullPolicy (should be IfNotPresent)
```

### Registry Down

```bash
# Check registry pod
kubectl get pods -n kube-system -l app=registry

# View logs
kubectl logs -n kube-system -l app=registry

# Restart registry
kubectl rollout restart deployment/registry -n kube-system
```

### Disk Space Issues

```bash
# Check node disk space
kubectl top nodes

# Clean up unused Docker images
docker system prune -a

# Clean registry
kubectl exec -n kube-system deploy/registry -- \
  registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
```

---

## Quick Reference Commands

```bash
# Load new version to registry
./scripts/load-to-registry.sh v1.1.0

# Deploy new customer
./scripts/deploy-customer.sh acme-corp arm64

# List all customers
kubectl get ns -l customer

# Update all customers to latest
for ns in $(kubectl get ns -l customer --no-headers -o custom-columns=":metadata.name"); do
  kubectl rollout restart deployment/codesys-arm64 -n $ns
done

# Check registry contents
curl http://localhost:5000/v2/_catalog

# View customer pod
kubectl get pods -n acme-corp

# View customer logs
kubectl logs -n acme-corp -l app=codesys -f
```

---

## Workflow Summary

```
┌─────────────────────────────────────────────────────┐
│ 1. Download from CODESYS Store (quarterly?)        │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 2. Upload to GitHub Releases (version control)     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 3. Run ./scripts/load-to-registry.sh v1.x.x        │
│    (GitHub → localhost:5000)                        │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 4. Deploy customers via kubectl or script          │
│    (Pulls from localhost:5000, instant!)           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 5. Customers activate licenses & use CODESYS        │
└─────────────────────────────────────────────────────┘
```

---

**This is your podstore. You own the distribution.** 🏭🚀

*Questions? Issues? Check SI_PARTNER_GUIDE.md or open an issue.*
