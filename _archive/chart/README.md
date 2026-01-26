# CODESYS Runtime ARM

**Industrial Automation PLC Runtime - IEC 61131-3 SoftPLC for ARM64**

Deploy CODESYS Control for Linux as a containerized PLC runtime with web-based HMI visualization. Perfect for industrial automation, SCADA systems, and edge computing applications.

## 🎯 Overview

CODESYS Control for Linux ARM SL is an IEC 61131-3-compliant SoftPLC that converts your ARM hardware into a high-performance industrial controller. This Helm chart deploys the runtime with integrated WebVisu web server in a single pod.

**Current Version:** CODESYS Control for Linux ARM SL 4.18.0.0

**GitHub Releases:**
- [ARM 64-Bit Release](https://github.com/fireball-industries/CodesysControlLinuxARM64/releases/tag/64-Bit)
- [ARM 32-Bit Release](https://github.com/fireball-industries/CodesysControlLinuxARM64/releases/tag/32-Bit)

**Architecture Support:**
- **ARM 32-bit (ARMv7)**: Raspberry Pi 2/3, older ARM boards
- **ARM 64-bit (ARMv8/AArch64)**: Raspberry Pi 4+, modern ARM platforms

## ✨ Key Features

- **Industrial PLC Runtime**: IEC 61131-3 compliant soft PLC
- **Dual Architecture**: ARM 32-bit (ARMv7) OR ARM 64-bit (ARMv8) selectable
- **Integrated WebVisu**: Built-in web server for browser-based HMI
- **Single Pod Design**: Runtime + WebVisu in one container
- **Fieldbus Support**: EtherCAT, PROFINET, Modbus, CANopen, etc.
- **OPC UA Server**: Built-in OPC UA support for Industry 4.0
- **Persistent Storage**: PLC programs and retains survive pod restarts
- **Demo Mode**: 2-hour demo mode for testing (auto-restart required)

## ⚠️ Important Disclaimers

1. **CODESYS officially does NOT support containers/VMs** - this is an unsupported deployment
2. Requires **privileged mode** for hardware I/O access (security consideration)
3. **Demo mode limitation**: Runtime stops after 2 hours without license
4. Use at your own risk - thoroughly test before production use

## 🚀 Quick Start

### Deploy via Rancher UI

1. Navigate to **Apps & Marketplace** → **Charts**
2. Search for "CODESYS Runtime"
3. Click **Install**
4. Configure:
   - License type (demo/soft-container/usb-dongle)
   - Resource presets
   - Storage configuration
   - Service types
5. Click **Install**

### Deploy via Helm CLI

```bash
helm repo add fireball-podstore https://YOUR-USERNAME.github.io/fireball-podstore-charts
helm repo update

# Basic installation (demo mode)
helm install my-plc fireball-podstore/codesys-runtime-arm \
  --namespace codesys-plc \
  --create-namespace

# With custom configuration
helm install my-plc fireball-podstore/codesys-runtime-arm \
  --namespace codesys-plc \
  --create-namespace \
  --set runtime.resources.preset=large \
  --set runtime.persistence.size=10Gi
```

## ⚙️ Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace for deployment | `codesys-plc` |
| `runtime.enabled` | Enable PLC runtime pod | `true` |
| `runtime.image.repository` | Runtime container image | `codesys/codesyscontrol-linux-arm64` |
| `runtime.image.tag` | CODESYS version | `4.18.0.0` |
| `runtime.resources.preset` | Resource preset | `medium` |
| `runtime.persistence.size` | Storage for PLC data | `5Gi` |
| `runtime.service.type` | Service type | `LoadBalancer` |
| `runtime.config.license.type` | License type | `demo` |
| `webvisu.enabled` | Enable WebVisu pod | `true` |
| `webvisu.service.type` | WebVisu service type | `LoadBalancer` |

### Resource Presets

#### Runtime Presets
- **Small**: 250m-500m CPU, 256Mi-512Mi RAM
- **Medium**: 500m-1000m CPU, 512Mi-1Gi RAM  
- **Large**: 1000m-2000m CPU, 1Gi-2Gi RAM

#### WebVisu Presets
- **Small**: 100m-500m CPU, 128Mi-512Mi RAM
- **Medium**: 250m-1000m CPU, 256Mi-1Gi RAM
- **Large**: 500m-2000m CPU, 512Mi-2Gi RAM

## 🔧 Usage

### Connecting from CODESYS Development System

1. **Get Runtime IP**:
   ```bash
   kubectl get svc -n codesys-plc
   ```

2. **In CODESYS IDE**:
   - Tools → Update Raspberry Pi (or scan network)
   - Enter IP address: `<RUNTIME_IP>:1217`
   - Login and download your PLC application

3. **Access WebVisu**:
   - Browser: `http://<RUNTIME_IP>:8080`
   - (Same IP as runtime - integrated in same pod)

### Demo Mode Management

Demo mode runs for 2 hours, then requires manual restart:

```bash
# Restart runtime to reset demo timer
kubectl rollout restart deployment -n codesys-plc -l app.kubernetes.io/component=plc-runtime

# Check runtime logs
kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime -f
```

### License Configuration

For production with real license:

```bash
helm upgrade my-plc fireball-podstore/codesys-runtime-arm \
  --set runtime.config.license.type=soft-container \
  --set runtime.config.license.content="BASE64_ENCODED_LICENSE"
```

## 🌐 Ports

| Port | Service | Protocol | Description |
|------|---------|----------|-------------|
| 1217 | Runtime | TCP | CODESYS communication |
| 4840 | OPC UA | TCP | OPC UA server |
| 8080 | WebVisu | HTTP | Web HMI interface (integrated) |

## 🔒 Security Considerations

### Privileged Mode

The runtime runs in privileged mode by default for hardware I/O access:

```yaml
runtime:
  securityContext:
    privileged: true
    capabilities:
      add:
        - SYS_ADMIN
        - SYS_NICE
        - SYS_RAWIO
        - NET_ADMIN
        - IPC_LOCK
```

**Recommendations**:
- Deploy to dedicated nodes with appropriate taints/tolerations
- Use network policies to restrict access
- Enable WebVisu authentication for production
- Audit logs regularly

### Host Network Access

Some fieldbus adapters require host network:

```yaml
runtime:
  hostNetwork: true
```

**Note**: This reduces network isolation - use cautiously.

## 📊 Monitoring

### Check Pod Status

```bash
kubectl get pods -n codesys-plc
kubectl describe pod -n codesys-plc <POD_NAME>
```

### View Logs

```bash
# Runtime logs
kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime -f

# WebVisu logs
kubectl logs -n codesys-plc -l app.kubernetes.io/component=webvisu -f
```

### PLC Diagnostics

Access via WebVisu or CODESYS IDE:
- CPU utilization
- Memory usage
- Task cycle times
- I/O status
- Communication diagnostics

## 🧪 Troubleshooting

### Runtime Won't Start

```bash
# Check events
kubectl get events -n codesys-plc --sort-by='.lastTimestamp'

# Check if storage is available
kubectl get pvc -n codesys-plc

# Verify privileged mode is allowed
kubectl describe pod -n codesys-plc <POD_NAME> | grep -i security
```

### Can't Connect from CODESYS IDE

1. Verify service has external IP:
   ```bash
   kubectl get svc -n codesys-plc
   ```

2. Check firewall rules (port 1217)

3. Verify runtime is running:
   ```bash
   kubectl logs -n codesys-plc -l app.kubernetes.io/component=plc-runtime --tail=50
   ```

### WebVisu Not Loading

1. Check WebVisu pod status:
   ```bash
   kubectl get pods -n codesys-plc -l app.kubernetes.io/component=webvisu
   ```

2. Verify runtime connectivity:
   ```bash
   kubectl exec -n codesys-plc <WEBVISU_POD> -- curl -v codesys-runtime:1217
   ```

### Demo Mode Expired

```bash
# Simply restart the deployment
kubectl rollout restart deployment -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

## 🎓 Best Practices

1. **Resource Allocation**: Start with medium preset, monitor, then adjust
2. **Storage**: Use fast storage class (SSD) for better PLC performance
3. **Networking**: LoadBalancer for external access, ClusterIP for internal only
4. **Backups**: Regularly backup PVC containing PLC programs
5. **Updates**: Test CODESYS version updates in dev before production
6. **Licensing**: Obtain proper licenses for production deployments
7. **Monitoring**: Integrate with Prometheus for metrics collection

## 📚 Additional Resources

- [CODESYS Documentation](https://content.helpme-codesys.com/)
- [IEC 61131-3 Standard](https://www.plcopen.org/iec-61131-3)
- [WebVisu Guide](https://content.helpme-codesys.com/en/CODESYS%20Visualization/_visu_start_page.html)
- [OPC UA Specification](https://opcfoundation.org/)

## 🏢 About

**Fireball Industries Podstore** - Industrial automation meets cloud-native infrastructure.

Crafted by **Patrick Ryan** for engineers who want their PLCs to run like it's 2026, not 1996.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/fireball-industries/fireball-podstore-charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fireball-industries/fireball-podstore-charts/discussions)
- **Documentation**: [Chart Repository](https://github.com/fireball-industries/fireball-podstore-charts)

---

**Built with HATE by Fireball Industries | Automating the Future**

