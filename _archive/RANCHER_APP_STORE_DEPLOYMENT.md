# CODESYS Runtime - Rancher App Store Deployment Guide

**Multi-Tenant Self-Service PLC Deployment Platform**

---

## 📋 Overview

This guide explains how to deploy the CODESYS Runtime Helm chart to Rancher's App Store (Catalog) for **multi-tenant self-service deployment**. Clients subscribe to the catalog, browse available apps, and deploy their own PLC instances without administrator intervention.

### Multi-Tenant Self-Service Architecture

**Deployment Model:**
```
Rancher App Catalog (Global)
    ↓
Client/Tenant Subscribes → Self-Service Access
    ↓
Tenant Chooses Configuration → Deploys to Their Namespace
    ↓
Isolated PLC Instance (Per Tenant)
    ↓
Fleet Available (Support/Troubleshooting Fallback)
```

**Benefits:**
- 🎯 **Self-Service**: Clients deploy and manage their own instances
- 🏢 **Multi-Tenant**: Complete isolation between client deployments
- 🔒 **Namespace Isolation**: Each tenant gets dedicated namespace(s)
- 🎨 **Customizable**: Clients choose architecture, resources, storage
- 🚀 **On-Demand**: Deploy instances when needed, scale as required
- 🛠️ **Fleet Fallback**: Admin-managed Fleet available for support cases

**What's Included:**
- ✅ Complete Helm chart with Rancher integration
- ✅ Interactive UI wizard via `questions.yaml` (self-service friendly)
- ✅ Support for ARM32 and ARM64 architectures
- ✅ Integrated WebVisu web server
- ✅ OPC UA server
- ✅ Persistent storage for PLC programs
- ✅ Resource presets (small/medium/large)
- ✅ Demo and production license modes
- ✅ Namespace auto-creation per tenant
- ✅ RBAC-ready for tenant isolation

---

## 📁 Chart Structure

The complete Helm chart is located in the `chart/` directory:

```
chart/
├── Chart.yaml                    # Chart metadata with Rancher annotations
├── values.yaml                   - Multi-Tenant Self-Service (Recommended)

This is the primary deployment method for your multi-tenant environment where clients can self-service deploy their PLC instances.

#### Prerequisites
- Rancher 2.6.0 or higher
- Kubernetes 1.25.0 or higher
- Multi-tenancy configured in Rancher (Projects/Namespaces)
- RBAC policies configured per tenant (optional but recommended)

#### Step 1: Add Chart to Global Catalog (Administrator Task - One Time)

**This step is performed once by the platform administrator to make the chart available to all tenants.**

**Option A: Git Repository (Recommended for Continuous Updates)**

1. In Rancher UI, go to **Cluster Management** → **Advanced** → **Repositories**
2. Click **Create**
3. Configure:
   - **Name**: `fireball-podstore` (or your choice)
   - **Target**: `Git repository containing Helm chart`
   - **Git Repo URL**: `https://github.com/YOUR-USERNAME/codesys_arm_64.git`
   - **Git Branch**: `main` (or your branch)
   - **Helm Index Directory**: `chart`
   - **Scope**: `All downstream clusters` (for multi-cluster) or specific cluster
4. Click **Create**

**Result**: The CODESYS Runtime chart becomes available to all users/tenants with appropriate permissions

---

## 🚀 Deployment Methods

### Method 1: Rancher App Catalog (Recommended for Rancher Users)

#### Prerequisites
- Rancher 2.6.0 or higher
- Kubernetes 1.25.0 or higher
- Access to Rancher's Apps & Marketplace

#### Step 1: Add Chart to Rancher Catalog

**Option A: Git Repository (Recommended)**

1. In Rancher UI, go to **Cluster Management** → **Advanced** → **Repositories**
2. Click **Create**
3. Configure:
   - **Name**: `fireball-podstore` (or your choice)
   - **Target**: `Git repository containing Helm chart`
   - **Git Repo URL**: `https://github.com/YOUR-USERNAME/codesys_arm_64.git`
   - **Git Branch**: `main` (or your branch)
   - **Helm Index Directory**: `chart`
4. Click **Create**

**Option B: Helm HTTP Repository**

If you're publishing to a Helm repository (like GitHub Pages):

1. Package the chart:
   ```bash
   helm package chart/
   helm repo Client/Tenant Self-Service Deployment

**Each client/tenant performs this independently to deploy their own PLC instance(s).**

1. **Login to Rancher** with tenant credentials
2. **Select Project/Cluster** where you have deployment permissions
3. Navigate to **Apps** → **Charts**
4. Search for "**CODESYS Runtime**" in the catalog
5. Click **Install**

6. **Configure via the Self-Service Wizard**:
   
   **Namespace Configuration** (Tenant Isolation):
   - **Namespace**: Choose unique name per instance (e.g., `client-acme-plc-1`, `tenant-smith-production`)
   - **Create NamespYour Runtime (Client Self-Service)

After deployment completes, Rancher displays installation notes with access instructions.

**Get Your Service Details:**
```bash
# Replace with your namespace
kubectl get svc -n <your-namespace>
```

**Example for client "acme":**
```bash
kubectl get svc -n client-acme-plc-1
```

**Connect from CODESYS IDE:**
- Address: `<EXTERNAL-IP>:1217`
- Username: `admin` (default)
- Download your PLC application

---

## 🏢 Multi-Tenant RBAC & Access Control

### Recommended RBAC Setup

#### Per-Tenant Namespace Access

Create Rancher Projects or use namespace-scoped RBAC to ensure tenants can only access their own namespaces.

**Example Rancher Project Setup:**
```yaml
Project: client-acme
├── Namespace: acme-plc-prod
├── Namespace: acme-plc-dev
└── Members: 
    ├── user@acme.com (Owner)
    └── developer@acme.com (Member)
```

**Tenant Permissions:**
- ✅ Deploy apps in their namespaces
- ✅ View/edit their deployments
- ✅ Access logs and metrics
- ❌ Cannot see other tenant namespaces
- ❌ Cannot modify catalog (admin only)

#### Service Account per Deployment

Each chart deployment creates its own service account:
```yaml
runtime:
  serviceAccount:
    create: true  # Isolated per deployment
    name: ""      # Auto-generated unique name
```

### Network Isolation

Enable Kubernetes Network Policies for tenant isolation:

```yaml
# In values.yaml or via UI
networkPolicy:
  enabled: true  # Restricts inter-namespace communication
```

**Result**: Each tenant's PLC can only communicate within its namespace unless explicitly allowed.

---

## 🛠️ Fleet Integration (Support Fallback)

While the App Store provides self-service deployment, **Fleet** remains available for:

### When to Use Fleet Instead of App Store

1. **Troubleshooting**: Client has deployment issues
2. **Mass Deployment**: Administrator needs to deploy many instances
3. **Template Enforcement**: Specific configurations must be enforced
4. **Emergency Recovery**: Rapid deployment of standardized config

### Fleet + App Store Coexistence

```
Normal Flow (Self-Service):
Client → Rancher App Store → Deploy → Manage

Support Flow (Admin Assisted):
Client Reports Issue → Admin Uses Fleet → Deploy/Fix → Hand Back to Client

Mass Deployment (Admin):
Admin → Fleet GitOps → Deploy 50 instances → Clients manage via App Store
```

**Key Point**: Fleet is the **fallback/support tool**, not the primary client interface.

---

## 📋 Self-Service Best Practices

### For Clients/Tenants

1. **Namespace Naming**: Use clear, unique names (e.g., `<company>-<purpose>-plc`)
2. **Start with Demo**: Test with demo license before purchasing
3. **Right-Size Resources**: Start with `medium` preset, adjust as needed
4. **Enable Persistence**: Always enable for production workloads
5. **Document Configuration**: Note your settings for future reference

### For Platform Administrators

1. **Quota Management**: Set resource quotas per namespace/project
2. **Storage Classes**: Provide multiple classes (fast-ssd, standard, etc.)
3. **Network Policies**: Enable by default for isolation
4. **Monitoring**: Deploy Prometheus/Grafana for all tenants
5. **Backup Strategy**: Automated PVC snapshots per namespace
6. **Support Documentation**: Provide clear guides for self-service

---

## 🎯 Client Self-Service Workflow

### Complete Deployment Workflow

```
1. Client Subscribes/Gets Access
   ↓
2. Login to Rancher with Credentials
   ↓
3. Navigate to Apps → Charts
   ↓
4. Find "CODESYS Runtime" in Catalog
   ↓
5. Click Install → Configure via Wizard
   ↓
6. Choose Namespace (auto-created)
   ↓
7. Select Architecture (ARM32/ARM64)
   ↓
8. Choose Resources (Small/Medium/Large)
   ↓
9. Configure Storage Size
   ↓
10. Select Service Type
    ↓
11. Click Install → Wait 1-2 Minutes
    ↓
12. Get Access Info from NOTES
    ↓
13. Connect CODESYS IDE & Program PLC
    ↓
14. Access WebVisu for HMI
    ↓
15. Manage/Scale via Rancher UI
```

**No Administrator Intervention Required** ✅

---

### Method 2: Helm CLI Deployment (Advanced Users/Automation)

For tenants with CLI access or automation needs.

#### Prerequisites
- Helm 3.x installed
- kubectl configured for your cluster
- Access to your namespace(s)

#### Deploy with Default Settings

```bash
# From the repository root
helm install my-plc ./chart \
  --namespace my-company
#### Scenario 1: Single Client, Multiple PLC Instances
```
Client: ACME Manufacturing
├── Namespace: acme-line-1-plc     → Production Line 1
├── Namespace: acme-line-2-plc     → Production Line 2  
└── Namespace: acme-development    → Testing/Development
```

Each deployment is independent with isolated resources.

#### Scenario 2: Multiple Clients, One Instance Each
```
Tenant: Acme Corp
└── Namespace: acme-production-plc → Their PLC

Tenant: Smith Industries  
└── Namespace: smith-plc-main      → Their PLC

Tenant: Johnson MFG
└── Namespace: johnson-edge-plc    → Their PLC
```

Complete isolation between tenants.

#### Scenario 3: Client with Staging/Production
```
Client: ACME Manufacturing
├── Namespace: acme-plc-dev        → Development (demo license)
├── Namespace: acme-plc-staging    → Staging (demo license)
└── Namespace: acme-plc-prod       → Production (full license)
```

Different configurations per environment.
   - **Enable WebVisu**: Checked (includes web HMI)
   - **Enable Ingress**: Optional - for hostname-based access
   
7. Click **Install**

**Result**: Tenant gets their own isolated CODESYS PLC instance in their dedicated namespace
4. Configure via the wizard:
   - **Namespace**: `codesys-plc` (or custom)
   - **Architecture**: Select `arm64` or `arm32`
   - **License Type**: `demo`, `soft-container`, or `usb-dongle`
   - **Resources**: Choose preset or custom
   - **Storage**: Configure PVC size and storage class
   - **Service Type**: `LoadBalancer`, `NodePort`, or `ClusterIP`
5. Click **Install**

#### Step 3: Access the Runtime

After deployment, Rancher will display the NOTES with access instructions.

**Get Service Details:**
```bash
kubectl get svc -n codesys-plc
```

**Connect from CODESYS IDE:**
- Address: `<EXTERNAL-IP>:1217`

**Access WebVisu:**
- URL: `http://<EXTERNAL-IP>:8080`

**OPC UA Endpoint:**
- URL: `opc.tcp://<EXTERNAL-IP>:4840`

---

### Method 2: Helm CLI Deployment

#### Prerequisites
- Helm 3.x installed
- kubectl configured for your cluster

#### Deploy with Default Settings

```bash
# From the repository root
helm install my-plc ./chart \
  --namespace codesys-plc \
  --create-namespace
```

#### Deploy with Custom Configuration

```bash
helm install my-plc ./chart \
  --namespace codesys-plc \
  --create-namespace \
  --set runtime.architecture.type=arm64 \
  --set runtime.resources.preset=large \
  --set runtime.persistence.size=10Gi \
  --set runtime.service.type=LoadBalancer
```

#### Deploy with Values File

```bash
# Using the production example
helm install my-plc ./chart \
  --namespace codesys-plc \
  --create-namespace \
  --values ./chart/examples/production-values.yaml
```

#### Upgrade Existing Deployment

```bash
helm upgrade my-plc ./chart \
  --namespace codesys-plc \
  --reuse-values \
  --set runtime.resources.preset=large
```

#### Uninstall

```bash
helm uninstall my-plc --namespace codesys-plc
```

---

## ⚙️ Configuration Options

### Key Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `namespace.name` | Deployment namespace | `codesys-plc` | Any valid namespace |
| `namespace.create` | Auto-create namespace | `true` | `true`, `false` |
| `runtime.architecture.type` | CPU architecture | `arm64` | `arm32`, `arm64` |
| `runtime.image.repository` | Container image | `ghcr.io/fireball-industries/codesys-runtime-arm64` | Any valid image |
| `runtime.image.tag` | CODESYS version | `4.18.0.0` | Any valid tag |
| `runtime.replicaCount` | Number of replicas | `1` | Typically `1` for PLC |
| `runtime.resources.preset` | Resource allocation | `medium` | `small`, `medium`, `large`, `custom` |
| `runtime.persistence.enabled` | Enable persistent storage | `true` | `true`, `false` |
| `runtime.persistence.size` | PVC storage size | `5Gi` | e.g., `10Gi`, `20Gi` |
| `runtime.service.type` | Service type | `LoadBalancer` | `LoadBalancer`, `NodePort`, `ClusterIP` |
| `runtime.config.license.type` | License mode | `demo` | `demo`, `soft-container`, `usb-dongle` |
| `runtime.config.webvisu.enabled` | Enable WebVisu | `true` | `true`, `false` |
| `runtime.hostNetwork` | Use host network | `false` | `true` for EtherCAT/PROFINET |
| `runtime.ingress.enabled` | Enable ingress | `false` | `true`, `false` |

### Resource Presets

#### Runtime Presets
- **small**: 250m-500m CPU, 256Mi-512Mi RAM
- **medium**: 500m-1000m CPU, 512Mi-1Gi RAM  
- **large**: 1000m-2000m CPU, 1Gi-2Gi RAM

### Custom Resources Example

```yaml
runtime:
  resources:
    preset: custom
    custom:
      requests:
        cpu: "750m"
        memory: "768Mi"
      limits:
        cpu: "1500m"
        memory: "1536Mi"
```

---

## 📝 Example Configurations

### Development Environment

```yaml
# chart/examples/development-values.yaml
namespace:
  name: "codesys-dev"
  
runtime:
  architecture:
    type: "arm64"
  
  resources:
    preset: "small"
  
  persistence:
    size: "2Gi"
  
  service:
    type: "NodePort"
  
  config:
    license:
      type: "demo"
    runtimeMode: "Debug"
    logLevel: "Debug"
```

Deploy:
```bash
helm install dev-plc ./chart \
  --values ./chart/examples/development-values.yaml
```

### Production Environment

```yaml
# chart/examples/production-values.yaml
namespace:
  name: "codesys-production"
  
runtime:
  architecture:
    type: "arm64"
  
  resources:
    preset: "large"
  
  persistence:
    enabled: true
    size: "20Gi"
    storageClassName: "fast-ssd"
  
  service:
    type: "LoadBalancer"
    loadBalancerIP: "192.168.1.100"
  
  config:
    license:
      type: "soft-container"
      content: "BASE64_ENCODED_LICENSE_HERE"
    runtimeMode: "Release"
    logLevel: "Warning"
    realtime:
      enabled: true
      priority: 80
  
  ingress:
    enabled: true
    className: "nginx"
    hosts:
      - host: plc.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: plc-tls
        hosts:
          - plc.example.com
  
  nodeSelector:
    node-role.kubernetes.io/plc: "true"
```

Deploy:
```bash
helm install prod-plc ./chart \
  --values ./chart/examples/production-values.yaml
```

---

## 🔍 Verification & Testing

### Check Deployment Status

```bash
# Check all resources
kubectl get all -n codesys-plc

# Check pod status
kubectl get pods -n codesys-plc -l app.kubernetes.io/component=plc-runtime

# View detailed pod info
kubectl describe pod -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

### View Logs

```bash
# Runtime logs
kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime -f

# Follow logs from specific pod
kubectl logs -n codesys-plc <POD_NAME> -f
```

### Test Connectivity

```bash
# Get service endpoint
kubectl get svc -n codesys-plc

# Test CODESYS port
nc -zv <EXTERNAL-IP> 1217

# Test WebVisu port
curl http://<EXTERNAL-IP>:8080

# Test OPC UA port
nc -zv <EXTERNAL-IP> 4840
```

### Access Pod Shell

```bash
kubectl exec -it -n codesys-plc deployment/my-plc-runtime -- /bin/sh
```

---

## 🔧 Troubleshooting

### Pod Won't Start

**Check Events:**
```bash
kubectl get events -n codesys-plc --sort-by='.lastTimestamp'
```

**Check Pod Description:**
```bash
kubectl describe pod -n codesys-plc <POD_NAME>
```

**Common Issues:**
- **Privileged mode denied**: Check cluster security policies
- **PVC pending**: Check storage class availability
- **Image pull errors**: Verify image repository and tag

### Can't Connect from CODESYS IDE

**Verify Service:**
```bash
kubectl get svc -n codesys-plc
```

**Check Firewall:**
- Ensure port 1217 is open
- For NodePort, ensure node firewall allows traffic

**Test Port:**
```bash
telnet <EXTERNAL-IP> 1217
```

### Demo Mode Expired

Demo mode runs for 2 hours then stops. Restart the deployment:

```bash
kubectl rollout restart deployment -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

### WebVisu Not Loading

**Check Runtime Logs:**
```bash
kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

**Verify WebVisu is Enabled:**
```bash
kubectl get deployment -n codesys-plc -o yaml | grep WEBVISU
```

### Resource Issues

**Check Resource Usage:**
```bash
kubectl top pod -n codesys-plc
```

**Increase Resources:**
```bash
helm upgrade my-plc ./chart \
  --namespace codesys-plc \
  --reuse-values \
  --set runtime.resources.preset=large
```

---

## 🔐 Security Considerations

### Privileged Mode

The runtime requires privileged mode for hardware I/O access. This is set by default:

```yaml
runtime:
  securityContext:
    privileged: true
```

**Recommendations:**
- Use dedicated nodes for PLC workloads
- Apply node taints and tolerations
- Enable network policies
- Regular security audits

### Network Policies

Enable network policies to restrict traffic:

```yaml
networkPolicy:
  enabled: true
```

### Service Account

The chart creates a dedicated service account. Configure with additional permissions as needed:

```yaml
runtime:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/ROLE
```

---

## 📊 Monitoring & Observability

### Prometheus Integration

Enable ServiceMonitor for Prometheus:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: "30s"
```

**Note:** Requires Prometheus Operator and CODESYS Prometheus library.

### Logging

View aggregated logs:

```bash
# All runtime logs
kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime

# With grep filter
kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime | grep ERROR
```

---

## 🔄 Upgrade & Maintenance

### Upgrade Chart Version

```bash
helm upgrade my-plc ./chart \
  --namespace codesys-plc \
  --reuse-values
```

### Change Configuration

```bash
# Upgrade with new values
helm upgrade my-plc ./chart \
  --namespace codesys-plc \
  --reuse-values \
  --set runtime.persistence.size=20Gi
```

### Rollback

```bash
# View history
helm history my-plc -n codesys-plc

# Rollback to previous version
helm rollback my-plc -n codesys-plc

# Rollback to specific revision
helm rollback my-plc 2 -n codesys-plc
```

### Backup PVC

```bash
# Create snapshot (if storage class supports it)
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: codesys-backup-$(date +%Y%m%d)
  namespace: codesys-plc
spec:
  source:
    persistentVolumeClaimName: my-plc-runtime-storage
EOF
```

---

## 📚 Additional Resources

### Chart Documentation
- **README.md**: Full chart documentation
- **ARCHITECTURE.md**: Technical architecture details
- **values.yaml**: All configuration options with comments

### CODESYS Resources
- [CODESYS Documentation](https://content.helpme-codesys.com/)
- [IEC 61131-3 Programming](https://www.plcopen.org/iec-61131-3)
- [CODESYS Store](https://store.codesys.com/)

### Kubernetes/Helm Resources
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Rancher Documentation](https://rancher.com/docs/)

---

## ❓ Support

### Issues & Bugs
- GitHub Issues: https://github.com/fireball-industries/fireball-podstore-charts/issues

### Questions & Discussion
- GitHub Discussions: https://github.com/fireball-industries/fireball-podstore-charts/discussions

---

## 📄 License

This Helm chart is provided as-is for deploying CODESYS Runtime. 

**CODESYS License:**
- Demo mode: Free for testing (2-hour limit)
- Production: Requires valid CODESYS license from CODESYS GmbH

**Important:** CODESYS officially does NOT support containerized deployments. Use at your own risk and test thoroughly.

---

**Built with 🔥 by Fireball Industries**  
**Patrick Ryan - patrick@fireball-industries.com**  
*Making industrial automation cloud-native since 2026*
