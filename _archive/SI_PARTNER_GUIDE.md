# Systems Integrator Partner Guide

*For SI partners deploying CODESYS to customer k3s clusters*

## Business Model Overview

This repository supports the following workflow:

1. **You (SI)** download CODESYS Control for Linux ARM SL from [CODESYS Store](https://store.codesys.com/en/codesys-control-for-linux-arm-sl-1.html)
2. **You** host the Docker images (GitHub Releases or Azure Blob Storage)
3. **Customers** download images from your hosted location
4. **Customers** deploy to their k3s clusters using provided manifests
5. **You** provide licensing (customers purchase through you)
6. **You** provide ongoing support and updates

## Initial Setup

### 1. Download Official Images

```bash
# Download from CODESYS Store
# https://store.codesys.com/en/codesys-control-for-linux-arm-sl-1.html

# You'll get:
# - CODESYS Control for Linux ARM64 SL (for ARMv8)
# - CODESYS Control for Linux ARM SL (for ARMv7)

# Extract and save as .tar files
mkdir -p images
# Place downloaded images here
mv ~/Downloads/codesys-*.tar images/
```

### 2. Choose Hosting Strategy

#### Option A: GitHub Releases (Simple, Free)

**Pros:**
- Free for public repos
- Versioning built-in
- Easy customer downloads
- No infrastructure to maintain

**Cons:**
- 2GB file size limit per asset
- Public by default (or expensive for private)
- No analytics on downloads

**Setup:**
```bash
# Tag a release
git tag -a v1.0.0 -m "Initial CODESYS ARM SL release"
git push origin v1.0.0

# Manually upload .tar files to GitHub Release
# (Too large for automated GitHub Actions upload)

# Customer download URL:
# https://github.com/<your-org>/<repo>/releases/download/v1.0.0/codesys-arm64.tar
```

#### Option B: Azure Blob Storage (Professional)

**Pros:**
- Handles large files easily
- Private access control
- Download analytics
- Can use CDN for faster downloads
- Looks more "enterprise"

**Cons:**
- Costs money (~$0.02/GB/month storage + egress)
- Requires Azure account
- More setup complexity

**Setup:**
```bash
# Install Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login
az login

# Create storage account (one-time)
az storage account create \
  --name yourcompanycodesys \
  --resource-group your-rg \
  --location eastus \
  --sku Standard_LRS

# Create container
az storage container create \
  --name codesys-images \
  --account-name yourcompanycodesys \
  --public-access off

# Upload images
az storage blob upload \
  --account-name yourcompanycodesys \
  --container-name codesys-images \
  --name codesys-arm64.tar \
  --file images/codesys-arm64.tar

az storage blob upload \
  --account-name yourcompanycodesys \
  --container-name codesys-images \
  --name codesys-arm32.tar \
  --file images/codesys-arm32.tar

# Generate SAS token (valid for 1 year)
az storage blob generate-sas \
  --account-name yourcompanycodesys \
  --container-name codesys-images \
  --name codesys-arm64.tar \
  --permissions r \
  --expiry $(date -u -d "1 year" '+%Y-%m-%dT%H:%MZ') \
  --https-only \
  --output tsv

# Give customers the full URL:
# https://yourcompanycodesys.blob.core.windows.net/codesys-images/codesys-arm64.tar?sp=r&st=...
```

**Pro Tip:** Create a landing page with download links + customer instructions

#### Option C: Both (Redundancy FTW)

Host on GitHub for easy access, mirror to Azure as backup. Best of both worlds.

## Customer Onboarding Process

### 1. Pre-Deployment Checklist

Before deploying for a customer, ensure:

- [ ] Customer has purchased CODESYS license through you
- [ ] Customer has ARM hardware with k3s installed
- [ ] You've provided download links (GitHub or Azure)
- [ ] You've provided this repository URL
- [ ] Customer understands licensing requirements
- [ ] Support SLA is established

### 2. Customer Deployment Options

**Option A: Customer Self-Deploy**
- Provide customer with [CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md)
- Customer follows deployment guide
- You provide remote support as needed

**Option B: Managed Deployment**
- You remotely access customer's k3s cluster
- You run deployment scripts
- You configure and test
- You hand off to customer

### 3. License Activation

After deployment:

```bash
# Customer provides you with:
# - Runtime ID (from CODESYS IDE after connecting)
# - Company info
# - Purchase order

# You:
# - Generate CODESYS license
# - Provide license file or activation code
# - Customer activates in CODESYS IDE
```

## Multi-Tenant Architecture

### Namespace Isolation Per Customer

```bash
# Customer A
kubectl create namespace customer-a-codesys
kubectl label namespace customer-a-codesys customer=customer-a
kubectl apply -f k8s/arm64/ -n customer-a-codesys

# Customer B
kubectl create namespace customer-b-codesys
kubectl label namespace customer-b-codesys customer=customer-b
kubectl apply -f k8s/arm64/ -n customer-b-codesys
```

### Resource Quotas Per Customer

```yaml
# customer-a-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: customer-a-quota
  namespace: customer-a-codesys
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
```

Apply:
```bash
kubectl apply -f customer-a-quota.yaml
```

### Network Policies (Isolate Customer Traffic)

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: customer-isolation
  namespace: customer-a-codesys
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Only allow traffic from customer's network
  - from:
    - ipBlock:
        cidr: 10.0.1.0/24  # Customer A's network
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow internet (for license validation, etc.)
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32  # Block metadata service
```

## Monitoring Customer Deployments

### Track Deployments

Create a spreadsheet/database:

| Customer | Namespace | Architecture | License Key | Deployed Date | Support Level | Status |
|----------|-----------|--------------|-------------|---------------|---------------|--------|
| Acme Inc | customer-acme | ARM64 | XXXX-XXXX | 2026-01-10 | Premium | Active |
| Widget Co | customer-widget | ARM32 | YYYY-YYYY | 2026-01-15 | Standard | Active |

### Monitoring Scripts

```bash
#!/bin/bash
# check-all-customers.sh

for ns in $(kubectl get ns -l customer --no-headers -o custom-columns=":metadata.name"); do
    echo "=== $ns ==="
    kubectl get pods -n $ns
    kubectl top pods -n $ns 2>/dev/null || echo "  (metrics not available)"
    echo ""
done
```

### Automated Health Checks

```bash
#!/bin/bash
# healthcheck-customers.sh

SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK"

for ns in $(kubectl get ns -l customer --no-headers -o custom-columns=":metadata.name"); do
    STATUS=$(kubectl get pods -n $ns -l app=codesys -o jsonpath='{.items[0].status.phase}')
    
    if [ "$STATUS" != "Running" ]; then
        curl -X POST $SLACK_WEBHOOK \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"Alert: Customer $ns CODESYS pod is $STATUS\"}"
    fi
done
```

## Updating Customer Deployments

When CODESYS releases updates:

1. Download new images from CODESYS Store
2. Upload to your hosting (GitHub/Azure)
3. Notify customers of available update
4. Update deployment manifests with new image tags

```bash
# Update image in deployment
kubectl set image deployment/codesys-arm64 \
  codesys-runtime=localhost:5000/codesys-arm64:v1.1.0 \
  -n customer-a-codesys

# Or use rolling update
kubectl rollout restart deployment/codesys-arm64 -n customer-a-codesys
```

## Billing Considerations

### Track Resource Usage

```bash
# Get resource usage per namespace (customer)
kubectl top pods -n customer-a-codesys
kubectl top nodes

# Get persistent volume usage
kubectl get pvc -n customer-a-codesys
```

### Cost Allocation

If running shared k3s cluster for multiple customers:

```bash
# Calculate costs based on:
# - CPU/Memory requests
# - Storage usage
# - Network egress
# - Support hours

# Example: Customer A uses 2 CPU, 4GB RAM, 10GB storage
# Your cost: $0.05/CPU-hour, $0.01/GB-RAM-hour, $0.10/GB-storage-month
# Monthly: (2 * 0.05 * 730) + (4 * 0.01 * 730) + (10 * 0.10) = $102.4
# Add margin + support = Customer price
```

## Support Playbook

### Common Customer Issues

**Issue: Container won't start**
```bash
# Debug steps
kubectl describe pod -n customer-x <pod-name>
kubectl logs -n customer-x <pod-name>

# Common fixes:
# - Image pull issues (re-import image)
# - Resource limits (increase requests/limits)
# - Config errors (check CODESYSControl.cfg)
```

**Issue: Can't connect from CODESYS IDE**
```bash
# Check service
kubectl get svc -n customer-x

# Check endpoints
kubectl get endpoints -n customer-x

# Test connectivity
telnet <service-ip> 1217

# Common fixes:
# - Firewall rules (customer's network)
# - Service type (change to NodePort if LoadBalancer fails)
# - License issues (verify license activated)
```

**Issue: License activation fails**
```bash
# Verify runtime can reach CODESYS license servers
kubectl exec -n customer-x <pod-name> -- ping licensing.codesys.com

# Check logs for license errors
kubectl logs -n customer-x <pod-name> | grep -i license

# Common fixes:
# - Network policies blocking outbound
# - Firewall blocking CODESYS license servers
# - Incorrect license key
```

## Best Practices

1. **Version Control**: Tag each customer deployment with version labels
2. **Backup Customer Data**: Automate PVC backups
3. **Documentation**: Maintain customer-specific deployment notes
4. **Monitoring**: Set up alerts for pod failures
5. **Updates**: Test updates in staging before production
6. **Security**: Use NetworkPolicies and RBAC
7. **Licensing**: Keep accurate license records

## Legal Compliance

- Ensure CODESYS partner agreement allows redistribution
- Track license usage per customer
- Maintain audit trail of deployments
- Include licensing terms in customer contracts
- Contact CODESYS for clarification on gray areas

---

**Questions?** Contact CODESYS partner support or open an issue in this repo.

*Building industrial automation solutions, one container at a time.* 🏭🚀
