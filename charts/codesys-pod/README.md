# Codesys Control ARM32 - Helm Chart

## Product Overview
**CODESYS Control** is the corresponding runtime system for the CODESYS Development System. It converts an industrial PC or embedded device (like Raspberry Pi or generic ARM Linux devices) into a high-performance IEC 61131-3 compatible programmable logic controller (PLC).

### Key Features
- **IEC 61131-3 Logic**: Supports all standard languages (ST, LD, FBD, SFC, AS).
- **Security**: Encrypted communication, user management, and secure boot integration.
- **Connectivity**: 
  - **OPC UA Server**: Built-in for SCADA/MES integration (Port 4840).
  - **Web Visualization**: HTML5-based HMI hosted directly on the controller (Port 8080).
  - **Fieldbus Support**: EtherCAT, PROFINET, EtherNet/IP, Modbus TCP/RTU.
- **Motion Control**: Optional SoftMotion support for single and multi-axis control.
- **Multicore Support**: Distribute tasks across CPU cores for real-time performance.

## Chart Description
This Helm chart deploys the **Codesys Control ARM32** runtime on Kubernetes clusters. It is optimized for Edge scenarios (K3s) and uses the **Installer Pattern** to fetch the official 32-bit runtime package and install it on a standard Debian container.

## Architecture

- **Base Image**: `debian:bullseye`
- **Installation**: Downloads the official CODESYS `.package` (Zip/Deb) at runtime via an `initContainer`.
- **Architecture**: Designed for **ARM64** devices (using 32-bit compatibility or native libraries) and **ARM32**.

## Installation

### From GitHub Pages (Recommended)

This repository is hosted as a Helm Chart repository.

```bash
# Add the repository
helm repo add embernet https://embernet-ai.github.io/codesys_arm_64

# Update repo cache
helm repo update

# Install the chart
helm install my-codesys embernet/codesys-pod
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Embernet-ai/codesys_arm_64.git
   cd codesys_arm_64
   ```

2. Install locally:
   ```bash
   helm install codesys ./charts/codesys-pod
   ```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `installerUrl` | URL to the CODESYS `.package` file | `.../v4.18.0.0/CODESYS.Control.for.Linux.ARM.32.bit...package` |
| `service.type` | Service type (LoadBalancer/NodePort) | `LoadBalancer` |
| `persistence.enabled` | Enable persistence for `/var/opt/codesys` | `true` |
| `persistence.size` | Size of the PVC | `5Gi` |

## Ports

- **1217**: Gateway (CODESYS IDE connection)
- **4840**: OPC UA Server
- **8080**: Web Visualization

## License

Contains installer logic for CODESYS Control. Users must have a valid CODESYS license for the runtime.
