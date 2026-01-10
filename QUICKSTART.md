# Quick Setup Guide

## Prerequisites Checklist

- [ ] ARM-based device (Raspberry Pi, NVIDIA Jetson, etc.)
- [ ] k3s installed
- [ ] Docker installed
- [ ] kubectl CLI available
- [ ] CODESYS Docker images downloaded

## Installation Steps

### 1. Install k3s (if not already installed)

```bash
curl -sfL https://get.k3s.io | sh -
```

Verify installation:
```bash
sudo k3s kubectl get nodes
```

### 2. Set up kubectl

```bash
# Copy k3s config for kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Verify
kubectl get nodes
```

### 3. Download CODESYS Images

Option 1: From CODESYS Store
- Visit https://store.codesys.com
- Download "CODESYS Control for Linux ARM SL"

Option 2: From GitHub Releases
- Visit this repository's Releases page
- Download appropriate `.tar` file for your architecture

### 4. Deploy CODESYS

#### For ARM64 (Raspberry Pi 4, NVIDIA Jetson, etc.)

```bash
# Clone this repository
git clone <your-repo-url>
cd codesys_arm_64

# Make script executable
chmod +x k8s/arm64/deploy.sh

# Deploy (adjust path to your docker image)
./k8s/arm64/deploy.sh /path/to/codesys-arm64.tar
```

#### For ARM32 (Raspberry Pi 3, etc.)

```bash
# Clone this repository
git clone <your-repo-url>
cd codesys_arm_64

# Make script executable
chmod +x k8s/arm32/deploy.sh

# Deploy (adjust path to your docker image)
./k8s/arm32/deploy.sh /path/to/codesys-arm32.tar
```

### 5. Verify Deployment

```bash
# Check if pod is running
kubectl get pods -n codesys

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# codesys-arm64-xxxxxxxxxx-xxxxx    1/1     Running   0          2m

# Check service
kubectl get svc -n codesys

# View logs
kubectl logs -n codesys -l app=codesys -f
```

### 6. Access CODESYS

#### Option A: Port Forwarding (for testing)

```bash
kubectl port-forward -n codesys svc/codesys-arm64 1217:1217 8080:8080
```

Then connect CODESYS IDE to `localhost:1217`

#### Option B: Direct Connection (production)

Get the service IP:
```bash
kubectl get svc -n codesys
```

Connect CODESYS IDE to `<EXTERNAL-IP>:1217`

## Verification Steps

### Test PLC Communication

1. Open CODESYS IDE
2. Go to "Scan Network"
3. Look for your device
4. Connect and download your application

### Test Web Visualization

Open browser to:
- `http://<service-ip>:8080`

### Test OPC UA

Connect OPC UA client to:
- `opc.tcp://<service-ip>:4840`

## Troubleshooting

### Pod not starting?

```bash
# Check pod details
kubectl describe pod -n codesys <pod-name>

# Check logs
kubectl logs -n codesys <pod-name>
```

### Can't connect from CODESYS IDE?

1. Verify service is running:
   ```bash
   kubectl get svc -n codesys
   ```

2. Check if port 1217 is accessible:
   ```bash
   telnet <service-ip> 1217
   ```

3. Check firewall rules on your device

### Image not loading?

```bash
# Check if image is imported
sudo k3s ctr images ls | grep codesys

# If not, manually import
docker load -i /path/to/codesys-arm64.tar
docker save <image-name> | sudo k3s ctr images import -
```

## Next Steps

- Read the full [README.md](README.md) for advanced configuration
- Configure persistent storage
- Set up monitoring
- Implement backup strategy
- Configure network policies

## Common Commands Reference

```bash
# View all resources
kubectl get all -n codesys

# Delete deployment
kubectl delete -f k8s/arm64/

# Restart deployment
kubectl rollout restart deployment/codesys-arm64 -n codesys

# Scale deployment
kubectl scale deployment/codesys-arm64 -n codesys --replicas=2

# Get pod logs
kubectl logs -n codesys -l app=codesys --tail=100 -f

# Execute command in pod
kubectl exec -it -n codesys <pod-name> -- /bin/bash
```

## Getting Help

- CODESYS Support: https://www.codesys.com/support
- k3s Documentation: https://docs.k3s.io
- Open an issue in this repository
