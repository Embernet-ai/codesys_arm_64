# Administrator Setup Guide - Multi-Tenant App Store

**One-Time Setup for Multi-Tenant CODESYS Runtime Deployment**

---

## 🎯 Overview

This guide is for **platform administrators** setting up the Rancher App Store catalog for multi-tenant self-service deployment. Once configured, clients can deploy their own PLC instances without admin intervention.

### What This Enables

**After Setup:**
- ✅ All tenants see "CODESYS Runtime" in their catalog
- ✅ Tenants can self-service deploy via UI wizard
- ✅ Each tenant gets isolated namespace(s)
- ✅ Automatic namespace creation per deployment
- ✅ Resource quotas and RBAC enforced
- ✅ Fleet available for admin support/troubleshooting

---

## Prerequisites

- Rancher 2.6.0+ installed and configured
- Kubernetes 1.25.0+ cluster(s)
- Admin access to Rancher (Cluster Owner or Global Admin)
- Git repository with this chart (already set up)
- Basic understanding of Rancher Projects and RBAC

---

## Step 1: Add Chart to Global Catalog

### Via Rancher UI (Recommended)

1. **Login to Rancher** as admin
2. Navigate to: **☰ (Hamburger Menu)** → **Cluster Management**
3. Select your cluster (or "local" for Rancher's own cluster)
4. Go to **Advanced** → **Repositories**
5. Click **Create**

6. **Configure Repository**:
   ```
   Name: fireball-codesys-runtime
   Target: Git repository containing Helm chart
   
   Git Repo URL: https://github.com/YOUR-ORG/codesys_arm_64.git
   Git Branch: main
   
   Helm Chart Path: chart
   ```

7. **Scope** (Important for Multi-Tenant):
   - Select **All downstream clusters** (makes available everywhere)
   - Or select specific clusters where you want it available

8. Click **Create**

**Result**: Chart is now in the catalog for all users with appropriate permissions.

### Via kubectl (Alternative)

```bash
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: fireball-codesys-runtime
spec:
  url: https://github.com/YOUR-ORG/codesys_arm_64.git
  gitBranch: main
  gitRepo: https://github.com/YOUR-ORG/codesys_arm_64.git
EOF
```

---

## Step 2: Configure Multi-Tenant RBAC

### Option A: Using Rancher Projects (Recommended)

Rancher Projects provide namespace grouping and RBAC in one place.

#### Create Project per Major Tenant

1. Go to **Cluster** → **Projects/Namespaces**
2. Click **Create Project**
3. Configure:
   ```
   Project Name: client-acme
   Description: ACME Manufacturing - PLC Deployments
   
   Resource Quotas (Optional):
   - Pods: 50
   - CPU Limit: 50 cores
   - Memory Limit: 100Gi
   - Storage: 500Gi
   ```

4. Click **Create**

#### Add Tenant Users to Project

1. Find the project you just created
2. Click **⋮** → **Edit Config**
3. Go to **Members** tab
4. Click **Add Member**
5. Configure:
   ```
   User: user@acme.com
   Role: Project Owner (or Project Member)
   ```

**Project Owner** can:
- Create namespaces in project
- Deploy apps in project namespaces
- Manage resources in project
- Cannot access other projects

#### Repeat for Each Major Tenant

```
Project: client-acme       → ACME users can access
Project: client-smith      → Smith users can access  
Project: client-johnson    → Johnson users can access
```

### Option B: Direct Namespace RBAC

For simpler setups or per-namespace access:

1. **Create Namespace** (or let tenant create via app deployment)
2. **Assign User to Namespace**:
   - Go to **Cluster** → **Projects/Namespaces**
   - Find namespace
   - Click **⋮** → **Edit Config**
   - Add **Members** with appropriate roles

---

## Step 3: Set Resource Quotas (Optional but Recommended)

### Cluster-Level Quotas

Prevent any tenant from consuming all cluster resources:

```yaml
# Apply via kubectl
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cluster-services-quota
  namespace: default
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 200Gi
    persistentvolumeclaims: "100"
EOF
```

### Per-Namespace Quotas

Set quotas when creating namespaces for tenants:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: client-acme-plc-1
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "5"
```

### Via Rancher Projects

Quotas automatically apply to all namespaces in the project.

---

## Step 4: Enable Network Policies (Security)

Enable network isolation between tenants:

### Cluster-Level Default Deny

```bash
# Create default deny policy for new namespaces
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

### Per-Chart Deployment

The chart includes network policy support. Recommend enabling by default:

1. When tenants deploy, they should enable:
   ```yaml
   networkPolicy:
     enabled: true
   ```

2. Or set as default in values.yaml before publishing

---

## Step 5: Configure Storage Classes

Provide multiple storage options for tenants:

### Create Storage Classes

```yaml
# Fast SSD storage (premium)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

---

# Standard storage (default)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

**Tenants can then choose** via the questions.yaml wizard.

---

## Step 6: Document for Tenants

### Create Tenant Onboarding Document

Provide clients with:

1. **Rancher URL**: `https://rancher.your-company.com`
2. **Login Credentials**: Username/password or SSO
3. **Quick Start Guide**: Share [QUICKSTART_RANCHER.md](QUICKSTART_RANCHER.md)
4. **Namespace Naming Convention**: 
   ```
   Format: <company>-<purpose>-plc
   Example: acme-line1-plc
   ```
5. **Support Contact**: How to reach you for issues
6. **Fleet Info**: "If you have issues, we can deploy via Fleet for you"

### Example Onboarding Email

```
Subject: Welcome to CODESYS PLC Self-Service Platform

Hello [Client Name],

You now have access to our Rancher-based PLC deployment platform!

Access Information:
- Rancher URL: https://rancher.company.com
- Username: yourname@company.com
- Password: [provided separately]

Quick Start:
1. Login to Rancher
2. Go to Apps → Charts
3. Search "CODESYS Runtime"
4. Click Install and follow the wizard

Documentation:
- Quick Start: [link to QUICKSTART_RANCHER.md]
- Full Guide: [link to RANCHER_APP_STORE_DEPLOYMENT.md]

Namespace Naming:
Please use format: yourcompany-purpose-plc
Example: acme-production-plc

Resource Limits:
- You can deploy up to 10 PLC instances
- Total CPU: 20 cores
- Total Memory: 40Gi
- Total Storage: 100Gi

Support:
If you have issues with self-service deployment, contact us and 
we'll deploy via Fleet for you.

Questions? Reply to this email.

Welcome aboard!
```

---

## Step 7: Test Self-Service Flow

### Validate End-to-End

1. **Create Test User** in Rancher
2. **Assign to Test Project**
3. **Login as Test User**
4. **Deploy CODESYS Runtime** via catalog
5. **Verify**:
   - Namespace created automatically
   - Pod starts successfully
   - Service gets external IP
   - User can access logs/metrics
   - User cannot see other namespaces

---

## Step 8: Monitor & Maintain

### Regular Admin Tasks

#### Monitor Catalog Health

```bash
# Check catalog sync status
kubectl get clusterrepos -A

# Check for chart updates
kubectl describe clusterrepo fireball-codesys-runtime
```

#### Monitor Resource Usage

```bash
# Per-namespace resource usage
kubectl top pods --all-namespaces | grep plc

# Check quota usage
kubectl get resourcequota --all-namespaces
```

#### Review Tenant Deployments

Via Rancher UI:
1. **Cluster** → **Workloads**
2. Filter by label: `app.kubernetes.io/name=codesys-runtime-arm`
3. View all tenant deployments across namespaces

### Automated Monitoring (Recommended)

Set up Prometheus/Grafana to track:
- Number of deployments per tenant
- Resource utilization per namespace
- Failed deployments (support needed)
- Storage usage trends

---

## Fleet Integration (Support Fallback)

### When to Use Fleet

Fleet should be used for:
- **Support Cases**: Tenant has deployment issues
- **Mass Deployment**: Need to deploy 50 instances quickly
- **Template Enforcement**: Must use specific config
- **Emergency**: Rapid standardized deployment needed

### Keep Fleet Configured

Maintain your Fleet deployment scripts from the original setup for:
1. Quick troubleshooting deployments
2. Standardized configurations
3. Bulk deployments when needed

**Fleet is backup, not primary** - tenants should self-service.

---

## Troubleshooting Common Issues

### Catalog Not Showing for Users

**Check**:
1. Repository sync status: `kubectl get clusterrepos`
2. User has access to cluster
3. Chart is in correct directory (`chart/` not root)
4. Branch name is correct

**Fix**:
```bash
# Force refresh
kubectl delete clusterrepo fireball-codesys-runtime
# Re-create via UI or kubectl
```

### Users Can't Create Namespaces

**Check**:
1. User role (needs Project Owner or Namespace Creator)
2. Project quotas not exceeded
3. Cluster quotas not exceeded

**Fix**: Assign proper role via Rancher UI

### Deployments Fail for Tenants

**Check**:
1. Resource quotas
2. Storage class availability
3. Privileged mode allowed in cluster
4. Network policies not blocking

**Support Option**: Deploy via Fleet to verify config, then hand back

---

## Best Practices

### For Multi-Tenant Success

1. **Clear Naming Conventions**: Enforce namespace naming
2. **Resource Quotas**: Prevent resource hogging
3. **Network Policies**: Enable isolation by default
4. **Documentation**: Keep tenant docs updated
5. **Monitoring**: Track usage and issues
6. **Support SLA**: Define when you'll use Fleet for them
7. **Regular Reviews**: Check tenant resource usage monthly

### Security Hardening

1. **Enable Pod Security Policies** (if not deprecated in your K8s version)
2. **Network Policies**: Default deny between namespaces
3. **RBAC**: Principle of least privilege
4. **Audit Logs**: Track who deploys what
5. **Image Scanning**: Verify container images

---

## Summary Checklist

### One-Time Setup
- [ ] Add chart to Rancher catalog (global scope)
- [ ] Create Projects for major tenants
- [ ] Assign users to Projects with appropriate roles
- [ ] Set up resource quotas per Project/namespace
- [ ] Enable network policies for isolation
- [ ] Configure storage classes
- [ ] Document and share with tenants
- [ ] Test self-service flow
- [ ] Set up monitoring/alerting

### Ongoing Maintenance  
- [ ] Monitor catalog sync status
- [ ] Review resource usage per tenant
- [ ] Handle support requests (use Fleet if needed)
- [ ] Update documentation as needed
- [ ] Add new tenants as they onboard
- [ ] Review and adjust quotas periodically

---

## Next Steps

1. **Complete Setup**: Follow steps 1-7 above
2. **Onboard First Tenant**: Test with friendly client
3. **Gather Feedback**: Improve documentation
4. **Scale**: Onboard remaining tenants
5. **Monitor**: Set up dashboards and alerts

---

## Support Resources

### Documentation for Tenants
- [QUICKSTART_RANCHER.md](QUICKSTART_RANCHER.md) - 5-minute guide
- [RANCHER_APP_STORE_DEPLOYMENT.md](RANCHER_APP_STORE_DEPLOYMENT.md) - Complete guide

### Documentation for Admins
- [VALIDATION_CHECKLIST.md](VALIDATION_CHECKLIST.md) - Pre-deployment validation
- [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - What's included
- This guide (ADMIN_SETUP_GUIDE.md) - Setup instructions

---

**You're ready to enable multi-tenant self-service PLC deployment!** 🚀

Once catalog is added, tenants can deploy in minutes without admin help.

---

**Built with 🔥 by Fireball Industries**  
*Empowering self-service industrial automation*
