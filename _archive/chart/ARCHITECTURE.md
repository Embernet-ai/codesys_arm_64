# CODESYS Chart Architecture - Corrected

## Summary of Changes

The CODESYS chart has been **corrected** to reflect the actual product architecture based on official CODESYS documentation.

## Previous (Incorrect) Architecture

❌ **What was wrong:**
- Chart had TWO separate pods: Runtime + WebVisu
- WebVisu was treated as a separate binary/service
- Only supported ARM 64-bit

## Current (Correct) Architecture

✅ **Corrected design:**
- **Single pod** containing CODESYS Control for Linux ARM SL
- **WebVisu is integrated** into the runtime (not a separate binary)
- Supports **both ARM 32-bit (ARMv7) and ARM 64-bit (ARMv8)**

## Product Details

### CODESYS Control for Linux ARM SL
**Product:** https://us.store.codesys.com/codesys-control-for-linux-arm-sl-1.html

**What it is:**
- IEC 61131-3 compliant PLC runtime
- Runs on Debian-based Linux (ARM 32-bit or 64-bit)
- **Includes WebVisu web server** (built-in, served by runtime)
- Supports OPC UA, fieldbus protocols (EtherCAT, PROFINET, Modbus, etc.)

**Ports:**
- 1217: CODESYS programming/debugging
- 4840: OPC UA server
- 8080: WebVisu HTTP (integrated web server)

**Architecture Options:**
- **32-bit**: ARMv7 platforms (Raspberry Pi 2/3, older ARM boards)
- **64-bit**: ARMv8/AArch64 platforms (Raspberry Pi 4+, modern ARM)

### CODESYS TargetVisu for Linux SL
**Product:** https://us.store.codesys.com/codesys-targetvisu-for-linux.html

**What it is:**
- **Separate Qt6-based GUI application**
- Runs on panels with physical displays (X11/Wayland)
- **Connects TO** the CODESYS runtime to display visualization
- Requires QT6 libraries, graphical environment

**Important:**
- This is a **different product** from the runtime
- Would require a **separate Helm chart** (codesys-targetvisu)
- Not implemented in this chart

## Implementation

### Helm Chart Structure

```
charts/codesys-runtime-arm/
├── Chart.yaml              # Metadata
├── values.yaml             # Single pod config with architecture selection
├── questions.yaml          # Rancher UI with arm32/arm64 selection
├── templates/
│   ├── namespace.yaml
│   ├── runtime-pvc.yaml
│   ├── runtime-serviceaccount.yaml
│   ├── runtime-deployment.yaml  # Single deployment with 3 ports
│   ├── runtime-service.yaml     # Exposes ports 1217, 4840, 8080
│   ├── ingress.yaml             # Optional ingress for WebVisu HTTP
│   ├── _helpers.tpl
│   └── NOTES.txt
├── examples/
│   ├── production-values.yaml
│   └── development-values.yaml
├── README.md
├── app-readme.md
└── .helmignore
```

### Key Configuration

```yaml
runtime:
  architecture:
    type: "arm64"  # or "arm32"
  
  image:
    repository: "codesys/codesyscontrol-linux-arm"
    tag: "4.18.0.0"
    # Final image: {repository}:{tag}-{architecture.type}
  
  service:
    ports:
      codesys:   { port: 1217, targetPort: 1217 }
      opcua:     { port: 4840, targetPort: 4840 }
      webvisu:   { port: 8080, targetPort: 8080 }
  
  config:
    webvisu:
      enabled: true  # Built-in web server
      port: 8080
      maxClients: 10
```

### Deployment Template

The runtime deployment now:
- Uses architecture-specific image tags: `-arm32` or `-arm64`
- Exposes 3 container ports: 1217, 4840, 8080
- Includes environment variables for WebVisu configuration
- Single container per pod (not two)

## User Impact

### Migration Notes

If users were testing the previous (incorrect) architecture:

1. **Remove old chart:**
   ```bash
   helm uninstall <release-name> -n codesys-plc
   ```

2. **Deploy corrected chart:**
   ```bash
   helm install my-plc ./charts/codesys-runtime \
     --set runtime.architecture.type=arm64
   ```

3. **Access changes:**
   - Runtime: Still `<IP>:1217`
   - WebVisu: Still `<IP>:8080` (now from same pod)
   - No separate WebVisu service to manage

### Benefits of Correction

✅ Accurate representation of CODESYS products  
✅ Simpler deployment (one pod vs two)  
✅ Lower resource usage (no separate WebVisu pod)  
✅ Proper architecture selection (arm32/arm64)  
✅ Aligns with official CODESYS documentation  

## Future: TargetVisu Chart

If you want local panel displays (CODESYS TargetVisu), a **separate chart** would be needed:

```
charts/codesys-targetvisu/
  - Qt6-based GUI container
  - Requires GPU/display passthrough
  - Connects to runtime pod via service
  - Different deployment altogether
```

This would be a separate implementation from the runtime chart.

---

**Corrected by:** Patrick Ryan, Fireball Industries  
**Date:** January 11, 2026  
**Reference:** Official CODESYS product documentation


