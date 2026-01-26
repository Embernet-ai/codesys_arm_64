# Customer Deployment Guide

*For customers who purchased CODESYS licensing through us*

## What You Need

Before you start, make sure you have:

- ✅ Valid CODESYS Control for Linux ARM SL license (purchased through your SI)
- ✅ ARM-based target device (Raspberry Pi 4, NVIDIA Jetson, etc.)
- ✅ k3s or Kubernetes cluster installed
- ✅ Download link for the Docker images (provided by your SI)
- ✅ A sense of adventure (or at least coffee)

## Step 1: Download Images

Your SI will provide you with a download link via:
- **GitHub Releases**: Check the releases page for the latest version
- **Azure Blob Storage**: Direct download URL with SAS token

Download the appropriate image for your architecture:
- `codesys-arm64.tar` for ARM64/ARMv8 devices (Raspberry Pi 4, etc.)
- `codesys-arm32.tar` for ARM32/ARMv7 devices (Raspberry Pi 3, etc.)

```bash
# Example: Download from Azure (your SI will give you the actual URL)
wget "https://<storage>.blob.core.windows.net/codesys-images/codesys-arm64.tar?<sas-token>" -O codesys-arm64.tar
```

## Step 2: Deploy to Your k3s Cluster

### Quick Deploy (Recommended)

Clone this repository:
```bash
git clone <repo-url>
cd codesys_arm_64
```

Place your downloaded `.tar` file in the `images/` directory:
```bash
mkdir -p images
mv ~/Downloads/codesys-arm64.tar images/
```

Run the deployment script:
```bash
# For ARM64
cd k8s/arm64
chmod +x deploy.sh
./deploy.sh ../../images/codesys-arm64.tar

# For ARM32
cd k8s/arm32
chmod +x deploy.sh
./deploy.sh ../../images/codesys-arm32.tar
```

### Verify Deployment

```bash
# Check if your pod is running
kubectl get pods -n codesys

# Should show something like:
# NAME                              READY   STATUS    RESTARTS   AGE
# codesys-arm64-xxxxxxxxxx-xxxxx    1/1     Running   0          2m

# Get your service IP
kubectl get svc -n codesys
```

## Step 3: Apply Your License

1. **Connect CODESYS IDE** to your runtime:
   - Get the service IP: `kubectl get svc -n codesys`
   - In CODESYS IDE, scan network or add device manually
   - Connect to `<SERVICE-IP>:1217`

2. **Activate your license**:
   - In CODESYS IDE, go to Tools → License Manager
   - Enter the license information provided by your SI
   - Activate the runtime license

## Step 4: Deploy Your Application

Now you're ready to:
1. Open your CODESYS project in the IDE
2. Set the connection to your k3s-hosted runtime
3. Download your application
4. Run and monitor your PLC logic

## Accessing Your Runtime

### Port Forwarding (Development/Testing)

```bash
kubectl port-forward -n codesys svc/codesys-arm64 1217:1217 8080:8080
```

Then connect to:
- **PLC**: `localhost:1217` (CODESYS IDE)
- **Web Visu**: `http://localhost:8080` (browser)

### Direct Access (Production)

```bash
# Get the LoadBalancer IP
kubectl get svc codesys-arm64 -n codesys
```

Connect to:
- **PLC**: `<EXTERNAL-IP>:1217`
- **Web Visu**: `http://<EXTERNAL-IP>:8080`
- **OPC UA**: `opc.tcp://<EXTERNAL-IP>:4840`

## Troubleshooting

### Container Keeps Restarting

```bash
# Check the logs
kubectl logs -n codesys -l app=codesys -f

# Common issues:
# - License not activated (fix: activate in CODESYS IDE)
# - Insufficient resources (fix: check node resources)
# - Configuration error (fix: check CODESYSControl.cfg)
```

### Can't Connect from CODESYS IDE

```bash
# Verify service is running
kubectl get svc -n codesys

# Test connectivity
telnet <SERVICE-IP> 1217

# Common issues:
# - Firewall blocking port 1217
# - Service not exposed (check service type)
# - Wrong IP address (use external IP, not cluster IP)
```

### Image Won't Load

```bash
# Verify image is imported
sudo k3s ctr images ls | grep codesys

# If not found, manually import
docker load -i codesys-arm64.tar
docker save <image-name> | sudo k3s ctr images import -
```

## Backup Your Data

Your application and data are stored in persistent volumes. Back them up regularly:

```bash
# Get pod name
POD=$(kubectl get pod -n codesys -l app=codesys -o jsonpath='{.items[0].metadata.name}')

# Backup PLC data
kubectl exec -n codesys $POD -- tar czf - /var/opt/codesys > codesys-backup-$(date +%Y%m%d).tar.gz
```

## Need Help?

Contact your Systems Integrator:
- For licensing issues
- For deployment assistance
- For configuration support
- For custom requirements

Or check the main [README.md](README.md) for detailed documentation.

## Security Recommendations

1. **Change default passwords** in CODESYS runtime (if any)
2. **Use network policies** to restrict access to your namespace
3. **Enable TLS** for OPC UA connections if used in production
4. **Regular updates**: Check with your SI for updated container images
5. **Monitor resource usage**: Set up alerts for CPU/memory limits

## Multi-Site Deployments

If you have multiple sites/locations:

```bash
# Site A
kubectl create namespace site-a
# Deploy to site-a namespace

# Site B  
kubectl create namespace site-b
# Deploy to site-b namespace
```

Each site gets isolated:
- Separate persistent storage
- Separate service endpoints
- Separate resource limits
- Independent scaling

---

**Questions?** Reach out to your SI. We're here to help! 🚀

*Remember: Your license is tied to your runtime. Don't lose your license info!*
