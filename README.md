# CODESYS Control for Linux ARM SL - Kubernetes Deployment

*Because running industrial automation software in containers on a Raspberry Pi is totally a normal Friday night activity* 🍕

## Overview

Look, we've all been there. You downloaded those CODESYS Docker images thinking "this will be easy," and now you're Googling "how to k8s" at 2 AM. Well, congratulations! You've found the repository that will either save your weekend or ruin it completely. 50/50 odds.

This repo contains everything you need to yeet CODESYS Control Runtime into the cloud (or your desk, we don't judge). Supports both ARM architectures because apparently we can't just pick one:

- **ARM64 (ARMv8)**: For people with money (Raspberry Pi 4, NVIDIA Jetson)
- **ARM32 (ARMv7)**: For people who "still have a Pi 3 laying around" (it's e-waste, Karen)

## Features

*What you get for your zero dollars:*

- ✅ Production-ready Kubernetes manifests (lol "production" on a Pi)
- ✅ Automated deployment scripts (because copying YAML is apparently too hard)
- ✅ Persistent storage (your data survives container deaths, unlike your will to live)
- ✅ LoadBalancer service exposure (fancy way of saying "makes it accessible")
- ✅ Health checks and probes (robots checking on other robots)
- ✅ Resource management (prevents your Pi from catching fire... probably)
- ✅ Kustomize support (YAML but make it ✨spicy✨)
- ✅ GitHub Actions workflow (automate the automation, very meta)

## Architecture

*It's containers all the way down*

```
CODESYS Control Runtime (the PLC that thinks it's special)
    ↓
Docker Container (prison for processes)
    ↓
Kubernetes Pod (fancy name for "container with extra steps")
    ↓
LoadBalancer Service (so other things can find your container prison)
    ↓
Your hopes and dreams (optional)
```

### Exposed Ports

*AKA "holes we punched in your security"*

- **1217**: PLC Communication (CODESYS protocol - it's proprietary, don't ask)
- **8080**: Web Visualization (because everything needs a web UI in 2026)
- **4840**: OPC UA Server (for when you want even MORE protocols)

## Prerequisites

### Required Software

*Things you need to install before you can procrastinate further:*

1. **k3s or Kubernetes cluster** (v1.20+)
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```
   *Yes, we're piping curl to shell. Living dangerously since 2015.*

2. **kubectl CLI** 
   ```bash
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   ```
   *Kubernetes' way of making you feel like a hacker*

3. **Docker** (for loading images)
   ```bash
   curl -fsSL https://get.docker.com | sh
   ```
   *More curling to shell because we're rebels*

### ARM Target Device Requirements

*Minimum specs (but like, we both know you're gonna try it on something worse):*

- ARM-based device (Raspberry Pi, NVIDIA Jetson, that thing from AliExpress)
- Linux OS (Ubuntu, Debian, Raspbian, whatever's hot this week)
- Minimum 1GB RAM (2GB+ recommended if you hate kernel OOMs)
- 5GB free disk space (more if you actually want to store data)

## Quick Start

*For the TL;DR crowd (respect)*

### 1. Download CODESYS Docker Images

Download the Docker images from:
- CODESYS Store: https://store.codesys.com (prepare your credit card)
- GitHub Releases (this repository - if I ever get around to uploading them)

Place the `.tar` files in an `images/` directory:
```
images/
├── codesys-arm64.tar  (thicc boi, probably 500MB+)
└── codesys-arm32.tar  (slightly less thicc)
```

### 2. Deploy to k3s

*The moment of truth. May the odds be ever in your favor.*

#### For ARM64 Devices:

**Linux/Bash** (for the purists):
```bash
cd k8s/arm64
chmod +x deploy.sh
./deploy.sh ../../images/codesys-arm64.tar
```

**PowerShell** (for the masochists):
```powershell
cd k8s\arm64
.\deploy.ps1 -DockerImageFile ..\..\images\codesys-arm64.tar
```

#### For ARM32 Devices:

**Linux/Bash:**
```bash
cd k8s/arm32
chmod +x deploy.sh
./deploy.sh ../../images/codesys-arm32.tar
```

**PowerShell:**
```powershell
cd k8s\arm32
.\deploy.ps1 -DockerImageFile ..\..\images\codesys-arm32.tar
```

### 3. Verify Deployment

*Cross your fingers edition*

```bash
# Check pod status (please be Running, please be Running)
kubectl get pods -n codesys

# Check service (did it work? spoiler: maybe)
kubectl get svc -n codesys

# View logs (where dreams go to die)
kubectl logs -n codesys -l app=codesys -f
```

## Manual Deployment

*For when you don't trust my scripts (fair)*

### 1. Load Docker Image

```bash
# Load the image
docker load -i images/codesys-arm64.tar

# Tag for local registry (if using)
docker tag <loaded-image> localhost:5000/codesys-arm64:latest

# For k3s without registry, import directly
# (because k3s has its own special container runtime, obviously)
docker save localhost:5000/codesys-arm64:latest | sudo k3s ctr images import -
```

### 2. Apply Kubernetes Manifests

*The YAML zone - prepare for indentation trauma*

```bash
# Create namespace (giving things their own space since therapy is expensive)
kubectl apply -f k8s/namespace.yaml

# Deploy ARM64 version
kubectl apply -f k8s/arm64/pvc.yaml
kubectl apply -f k8s/arm64/deployment.yaml
kubectl apply -f k8s/arm64/service.yaml

# OR deploy ARM32 version (choose your own adventure)
kubectl apply -f k8s/arm32/pvc.yaml
kubectl apply -f k8s/arm32/deployment.yaml
kubectl apply -f k8s/arm32/service.yaml
```

### 3. Wait for Readiness

*This is where you grab coffee and question your life choices*

```bash
# ARM64 (timeout after 5 minutes because we're not animals)
kubectl wait --for=condition=available --timeout=300s deployment/codesys-arm64 -n codesys

# ARM32
kubectl wait --for=condition=available --timeout=300s deployment/codesys-arm32 -n codesys
```

## Advanced Configuration

*For when basic wasn't extra enough*

### Using Kustomize

Kustomize allows you to customize deployments without modifying base manifests (because git conflicts are so 2020):

```bash
# Build and preview (see what chaos you're about to unleash)
kubectl kustomize k8s/arm64

# Apply with kustomize (YOLO)
kubectl apply -k k8s/arm64
```

### Custom Configuration

Edit [k8s/arm64/CODESYSControl.cfg](k8s/arm64/CODESYSControl.cfg) or [k8s/arm32/CODESYSControl.cfg](k8s/arm32/CODESYSControl.cfg) to customize CODESYS Control settings.

The configuration is loaded via ConfigMap. After changes:

```bash
# Recreate the deployment to pick up new config
# (IT'S NOT A BUG, IT'S A FEATURE)
kubectl rollout restart deployment/codesys-arm64 -n codesys
```

### Scaling Replicas

*Because one PLC wasn't enough chaos*

```bash
# Scale ARM64 deployment (more is better, right?)
kubectl scale deployment/codesys-arm64 -n codesys --replicas=3

# Scale ARM32 deployment
kubectl scale deployment/codesys-arm32 -n codesys --replicas=2
```

**Reality Check**: For PLC applications, you typically run a single replica. Multiple replicas are useful for redundancy, but please don't blame me when your state management becomes a nightmare.

### Persistent Storage

By default, deployments use k3s's `local-path` storage class with 5GB volumes (because we're optimists).

To modify, edit [k8s/arm64/pvc.yaml](k8s/arm64/pvc.yaml):
```yaml
spec:
  resources:
    requests:
      storage: 10Gi  # Go big or go home
  storageClassName: your-storage-class  # Use different storage (fancy!)
```

## Accessing CODESYS

*The part where you actually use this thing*

### Port Forwarding (Development)

For when you're too lazy to set up proper networking:

```bash
# Forward all ports locally (tunnel vision activated)
kubectl port-forward -n codesys svc/codesys-arm64 1217:1217 8080:8080 4840:4840

# Then connect CODESYS IDE to localhost:1217
# (yes, it's that easy when you cheat)
```

### LoadBalancer (Production)

Get the external IP:
```bash
kubectl get svc codesys-arm64 -n codesys
```

Connect CODESYS IDE to `<EXTERNAL-IP>:1217`

*Narrator: The LoadBalancer didn't work on the first try*

### NodePort Alternative

For environments without LoadBalancer support (looking at you, bare metal), modify [k8s/arm64/service.yaml](k8s/arm64/service.yaml):

```yaml
spec:
  type: NodePort  # The "good enough" solution
  ports:
  - name: plc-comm
    protocol: TCP
    port: 1217
    targetPort: 1217
    nodePort: 31217  # Accessible at <node-ip>:31217
```

## Monitoring and Troubleshooting

*The "why isn't this working" survival guide*

### View Logs

```bash
# Real-time logs (watch your dreams crash in real-time)
kubectl logs -n codesys -l app=codesys,arch=arm64 -f

# Previous crashed container (digital autopsy)
kubectl logs -n codesys <pod-name> --previous
```

### Debug Pod Issues

```bash
# Describe pod (wall of text incoming)
kubectl describe pod -n codesys <pod-name>

# Get events (Kubernetes' passive-aggressive error messages)
kubectl get events -n codesys --sort-by='.lastTimestamp'

# Execute commands in container (hack the planet)
kubectl exec -it -n codesys <pod-name> -- /bin/bash
```

### Check Resource Usage

```bash
# View resource metrics (requires metrics-server, which you probably don't have)
kubectl top pods -n codesys
kubectl top nodes
```

### Common Issues

*AKA things that will definitely go wrong*

#### Pod CrashLoopBackOff

Translation: "Your container keeps dying and we keep reviving it. We're in hell."

1. Check logs: `kubectl logs -n codesys <pod-name>`
2. Verify image loaded: `sudo k3s ctr images ls | grep codesys`
3. Check node architecture: `kubectl get nodes -o wide`
4. Accept that it's probably DNS (it's always DNS)

#### ImagePullBackOff

Translation: "We can't find your image and we've tried nothing and we're all out of ideas."

- Image not loaded or tagged correctly (classic you)
- For k3s: ensure image is imported with `k3s ctr images import`
- Check [k8s/arm64/deployment.yaml](k8s/arm64/deployment.yaml) image name matches
- Question all your life decisions

#### Service Not Accessible

Translation: "The container is running but good luck talking to it."

1. Check service: `kubectl get svc -n codesys`
2. Verify endpoints: `kubectl get endpoints -n codesys`
3. Check firewall rules (they're blocking you, guaranteed)
4. For LoadBalancer, ensure k3s has servicelb enabled (lol good luck)
5. Cry
6. Try turning it off and on again

## GitHub Releases

*For when you want to share your containerized chaos with the world*

### Creating a Release

1. Tag your repository (semantic versioning because we're professionals):
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0 - It works on my machine™"
   git push origin v1.0.0
   ```

2. Place Docker images in `images/` directory:
   ```
   images/
   ├── codesys-arm64.tar  (thicc)
   └── codesys-arm32.tar  (also thicc)
   ```

3. GitHub Actions will automatically:
   - Create a release (robots doing work)
   - Upload Docker images as release assets (if they fit, these files are CHONKY)
   - Generate release notes (with varying degrees of usefulness)

### Manual Upload

If GitHub Actions ghost you (they will):

1. Go to repository Releases (it's a tab, you'll find it)
2. Create new release (click buttons, feel powerful)
3. Upload `codesys-arm64.tar` and `codesys-arm32.tar` (RIP your internet connection)
4. Add release notes (or don't, we're not your mom)

## Project Structure

*What lives where in this digital nightmare:*

```
.
├── .github/
│   └── workflows/
│       └── release.yml          # Automation babysitter
├── images/                      # Your CHONKY Docker files live here
│   ├── codesys-arm64.tar       # (not included, download yourself)
│   └── codesys-arm32.tar       # (also not included, storage isn't free)
├── k8s/
│   ├── namespace.yaml           # Dedicated space for our containers
│   ├── arm64/
│   │   ├── deployment.yaml      # Where the magic happens
│   │   ├── service.yaml         # Networking things
│   │   ├── pvc.yaml             # Storage because data matters, apparently
│   │   ├── kustomization.yaml   # For the fancy people
│   │   ├── CODESYSControl.cfg   # CODESYS settings (don't break this)
│   │   ├── deploy.sh            # The lazy way (Bash edition)
│   │   └── deploy.ps1           # The lazy way (PowerShell edition)
│   └── arm32/
│       ├── deployment.yaml      # Same but different
│       ├── service.yaml         # Networking things (32-bit edition)
│       ├── pvc.yaml             # Storage (also important here)
│       ├── kustomization.yaml   # Still fancy
│       ├── CODESYSControl.cfg   # More settings to not break
│       ├── deploy.sh            # Automation for the win
│       └── deploy.ps1           # Windows people need love too
├── .gitignore                   # Keeping secrets secret
└── README.md                    # You are here (hi! 👋)
```

## Best Practices

*Things we should do but probably won't*

### Security

1. **Don't run as privileged** unless you enjoy living dangerously (we don't judge... much)
2. **Use secrets** for sensitive configuration (because plaintext passwords are so 2010):
   ```bash
   kubectl create secret generic codesys-credentials -n codesys \
     --from-literal=username=admin \
     --from-literal=password=yourpassword
   ```
3. **Network policies** to restrict access (paranoia is a feature):
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: codesys-network-policy
     namespace: codesys
   spec:
     podSelector:
       matchLabels:
         app: codesys
     policyTypes:
     - Ingress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: trusted-namespace
   ```

### High Availability

*For when uptime actually matters (unlike this README's quality)*

1. **Use multiple replicas** with proper state management (good luck with that)
2. **Configure pod disruption budgets** (Kubernetes' way of saying "don't kill all my pods at once"):
   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: codesys-pdb
     namespace: codesys
   spec:
     minAvailable: 1
     selector:
       matchLabels:
         app: codesys
   ```
3. **Set resource limits** to prevent resource exhaustion (and your Pi from becoming a space heater)
4. **Use anti-affinity** to spread pods across nodes (diversity is strength)

### Backup and Recovery

Because losing data builds character, but backups build careers:

```bash
# Export PVC data (digital time capsule)
kubectl exec -n codesys <pod-name> -- tar czf - /var/opt/codesys > backup.tar.gz

# Restore (the "oh no" button)
kubectl exec -n codesys <pod-name> -- tar xzf - -C / < backup.tar.gz
```

## License

This repository contains deployment configurations and scripts. CODESYS software is licensed separately by CODESYS GmbH. 

**Translation**: The scripts are free, the software isn't. Don't @ me, take it up with CODESYS.

Ensure you have appropriate licenses before deploying. We're not your lawyers.

## Resources

*Places to find help when this inevitably breaks:*

- [CODESYS Official Site](https://www.codesys.com) - The source of truth
- [CODESYS Store](https://store.codesys.com) - Where your money goes
- [CODESYS Documentation](https://help.codesys.com) - Actually helpful sometimes
- [k3s Documentation](https://docs.k3s.io) - Lightweight Kubernetes for people who hate complexity
- [Kubernetes Documentation](https://kubernetes.io/docs) - For when you hate yourself
- Stack Overflow - For when the docs fail you (so, always)

## Support

For issues with:
- **CODESYS software**: Contact CODESYS support (they get paid for this)
- **Deployment scripts/manifests**: Open an issue (I get paid in stars ⭐)
- **k3s/Kubernetes**: Read the fine manual (RTFM)
- **Your life choices**: Therapy (seriously, it helps)

## Contributing

Contributions welcome! Please:

1. Fork the repository (it's free real estate)
2. Create a feature branch (naming things is hard, we know)
3. Make your changes (break things, fix things, the circle of dev)
4. Submit a pull request (crossing fingers optional but recommended)

Guidelines:
- Keep the snark alive 
- Actually test your changes (revolutionary concept)
- Update docs if you change behavior (future you will thank present you)
- Don't be a jerk (we're all struggling here)

## Changelog

### v1.0.0 (2026-01-10)
- Initial release (it lives!)
- ARM64 and ARM32 deployment manifests (double the architectures, double the fun)
- Automated deployment scripts (robots doing our jobs)
- Kustomize support (for the YAML connoisseurs)
- GitHub Actions release workflow (automation on automation)
- Snarky README (you're welcome)

---

*Made with 💀 dark humor, ☕ excessive caffeine, and 😅 the realization that we're running PLCs in containers on Raspberry Pis*

**Remember**: If it works in production, it was a calculated decision. If it breaks, it was just a test. 

Now go forth and containerize all the things! 🚀
