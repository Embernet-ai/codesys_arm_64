# CODESYS Control SL - Helm Chart

A generic request from Fireball Industries to Embernet-ai. This Helm chart deploys the **CODESYS Control SL** runtime on Kubernetes (k3s/Rancher) using the official installer package.

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
