# Quick Start - Rancher App Store Self-Service Deployment

**Deploy Your Own CODESYS PLC Instance in 5 Minutes**

---

## 🎯 Multi-Tenant Self-Service Model

This is a **self-service platform** where you (the client/tenant) can deploy and manage your own PLC instances without administrator help. 

**Your Capabilities:**
- ✅ Deploy unlimited PLC instances (within quota)
- ✅ Choose your own namespace
- ✅ Select architecture (ARM32/ARM64)
- ✅ Configurccess the Catalog

**Note**: The catalog should already be available. This step was done by your administrator.

1. **Login to Rancher** with your credentials
2. **Select your cluster** (if you have access to multiple)
3. Go to **Apps** → **Charts**
4. Verify you can see "**CODESYS Runtime**" in the available charts

**If you don't see the chart:**
- Contact your administrator
- You may need permissions to the catalog
- Or the catalog hasn't been added yet (admin task)Name: codesys-runtime
   Target: Git repository containing Helm chart
   Git Repo URL: <YOUR_GIT_REPO_URL>
   Git Branch: main
   Helm Index Directory: chart
   ```
5. Click **Create**

### Option B: Via kubectl

```bash
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: codesys-runtime
spec:
  gitRepo: <YOUR_GIT_REPO_URL>
  gitBranch: main
  helmChartPath: chart
EOF
```

---

## Step 2: Install from Rancher Catalog

1. Go to **Apps** → **Charts**
2. Search for "**CODESYS Runtime**"
3. Click **Install**
4. Configure in wizard:

### Minimal Configuration (Demo Mode)
```
Namespace: codesys-plc (auto-create)
Architecture: arm64
License Type: demo
Resource Preset: medium
Storage Size: 5Gi
Service Type: LoadBalancer
```

5. Click **Install**
6. Wait forDeploy Your PLC Instance (Self-Service)

1. Go to **Apps** → **Charts**
2. Search for "**CODESYS Runtime**"
3. Click **Install**
4. **Configure in the wizard**:

### Choose Your Configuration

#### Namespace (Important - Makes It Yours!)
```
Namespace: my-company-plc-1        ← Choose unique name
Create Namespace: ✓ (checked)     ← Auto-creates it for you
```

**Naming Convention**: `<your-company>-<purpose>-plc`
- Examples: `acme-line1-plc`, `smith-production`, `johnson-dev-plc`

#### Basic Settings
```
Architecture: arm64                ← or arm32 for older hardware
License Type: demo                 ← Free 2-hour demo mode
Resource PresetYour Access Information

### Via Rancher UI (Easiest)
1. Go to **Service Discovery** → **Services** (or **Workloads** → **Services**)
2. **Filter by your namespace** (e.g., `my-company-plc-1`)
3. Find the service ending in `-runtime`
4. Note the **External IP** (or LoadBalancer IP)

### Via kubectl (Advanced)
```bash
# Replace with YOUR namespace
kubectl get svc -n my-company-plc-1

# Wait for external IP if pending
kubectl get svc -n my-company-plc-1 -w
```

Example output:
```
NAME                    TYPE           EXTERNAL-IP      PORT(S)
my-plc-runtime          LoadBalancer   192.168.1.100    1217:30217/TCP,4840:30840/TCP,8080:30080/TCP
```

**Your External IP**: `192.168.1.100` (example - yours will differ)Open CODESYS IDE
2. Tools → Update Raspberry Pi (or scan network)
3. Enter IP: `192.168.1.100:1217`
4. Login and download your PLC program

### WebVisu (Web Interface)
- Open browser: `http://192.168.1.100:8080`
- No additional login required (demo mode)

### OPC UA Client
- Endpoint: `opc.tcp://192.168.1.100:4840`
- Security: None (demo mode)

---

## Common Tasks

### Restart Demo Runtime (2-hour limit)
```bash
kubectl rollout restart deployment -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

### View Logs
# Replace with YOUR namespace
kubectl rollout restart deployment -n my-company-plc-1 -l app.kubernetes.io/component=plc-runtime
```

### View Your Logs
```bash
# Replace with YOUR namespace
kubectl logs -n my-company-plc-1 -l app.kubernetes.io/component=plc-runtime -f
```

### Check Your Status
```bash
# Replace with YOUR namespace
kubectl get pods -n my-company-plc-1
kubectl get svc -n my-company-plc-1
```

### Upgrade Your Configuration (Self-Service)
1. In Rancher: **Apps** → **Installed Apps**
2. **Filter by your namespace**
3. Find your installation
4. Click **⋮** → **Edit/Upgrade**
5. Modify settings (change resources, storage, etc.)
6. Click **Upgrade**
7. **No admin approval needed** - you control it!

---

## 🏢 Multi-Tenant Scenarios

### Deploy Multiple Instances

You can deploy as many instances as you need (within quota):

```
Your Company Deployments:
├── my-company-line1-plc     → Production Line 1
├── my-company-line2-plc     → Production Line 2
├── my-company-dev-plc       → Development/Testing
└── my-company-backup-plc    → Hot Standby
```

Each deployment:
- ✅ Has its own namespace
- ✅ Gets its own external IP
- ✅ Isolated storage and resources
- ✅ Independent management

### Share Access with Team

Grant your team access via Rancher:
1. Go to **Cluster** → **Projects/Namespaces**
2. Find your namespace
3. Click **⋮** → **Edit Config**
4. Add **Members** (your colleagues)
5. Set permissions (Owner, Member, Read-Only)

---

## 🆘 When to Contact Admin / Use Fleet

### You Can Self-Service:
- ✅ Deploy new PLC instances
- ✅ Upgrade/downgrade resources
- ✅ Restart deployments
- ✅ View logs and metrics
- ✅ Scale or delete instances
- ✅ Configure networking

### Contact Admin / Fleet Support For:
- ❌ Catalog not appearing
- ❌ Cannot create namespaces (quota/permission issue)
- ❌ Persistent deployment failures
- ❌ Network policy issues
- ❌ Need mass deployment of many instances
- ❌ Cluster-level configuration needed

**Fleet is your fallback** if self-service isn't working.ment

For production use:

1. **Get CODESYS License**
   - Purchase from CODESYS GmbH
   - Encode as base64

2. **Use Production Settings**:
   ```
   License Type: soft-container
   License Content: <BASE64_ENCODED_LICENSE>
   Resource Preset: large
   Storage Size: 20Gi
   Runtime Mode: Release
   Log Level: Warning
   ```

3. **Enable Security**:
   - Configure Ingress with TLS
   - Enable network policies
   - Use dedicated nodes
   - Enable real-time (if RT kernel available)

4. **Configure Backup**:
   - Set up PVC snapshots
   - Backup PLC programs regularly

---

## Troubleshooting

### Pod Won't Start
```bash
# Check events
kubectl get events -n codesys-plc --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

### Can't Connect from CODESYS
- Verify external IP: `kubectl get svc -n codesys-plc`
- Check firewall allows port 1217
- Test connectivity: `telnet <EXTERNAL-IP> 1217`

### WebVisu Not Loading
- Check runtime logs: `kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime`
- Verify port 8080 is accessible
- Test: `curl http://<EXTERNAL-IP>:8080`

### Demo Expired
```bash
# Simply restart
kubectl rollout restart deployment -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

---

## Architecture Selection

### ARM32 (ARMv7)
- Raspberry Pi 2
- Raspberry Pi 3
- Older ARM boards
- Select: `runtime.architecture.type: arm32`

### ARM64 (ARMv8/AArch64)
- Raspberry Pi 4
- Raspberry Pi 5
- Modern ARM servers
- Select: `runtime.architecture.type: arm64`

---

## Resource Presets

| Preset | CPU Request | CPU Limit | Memory Request | Memory Limit |
|--------|-------------|-----------|----------------|--------------|
| Small  | 250m        | 500m      | 256Mi          | 512Mi        |
| Medium | 500m        | 1000m     | 512Mi          | 1Gi          |
| Large  | 1000m       | 2000m     | 1Gi            | 2Gi          |

Choose based on:
- **Small**: Simple PLC logic, few I/O points
- **Medium**: Typical industrial applications
- **Large**: Complex logic, many I/O, visualization

---

## Service Types

### LoadBalancer (Default)
- Automatic external IP
- Best for bare-metal/edge deployments
- Requires MetalLB or cloud provider

### NodePort
- Access via `<NodeIP>:<NodePort>`
- Fixed port range (30000-32767)
- Good for development/testing

### ClusterIP
- Internal cluster access only
- Use with Ingress for external access
- Most secure option

---

## Next Steps

1. **Learn More**: Read [RANCHER_APP_STORE_DEPLOYMENT.md](RANCHER_APP_STORE_DEPLOYMENT.md)
2. **Configure**: Check [chart/values.yaml](chart/values.yaml) for all options
3. **Examples**: See [chart/examples/](chart/examples/) for dev/prod configs
4. **Validate**: Review [VALIDATION_CHECKLIST.md](VALIDATION_CHECKLIST.md)

---

## Important Warnings

⚠️ **Demo Mode**: Stops after 2 hours, requires restart  
⚠️ **Privileged**: Runs in privileged mode for I/O access  
⚠️ **Unofficial**: CODESYS doesn't officially support containers  
⚠️ **Testing**: Test thoroughly before production use  
⚠️ **License**: Get proper license for production deployments

---

## Support

- **Documentation**: See docs in repository root
- **Issues**: GitHub Issues
- **Questions**: GitHub Discussions

---

**You're ready to go! Deploy and start programming your cloud-native PLC!** 🚀

---

Built with 🔥 by Fireball Industries | Making automation cloud-native since 2026
