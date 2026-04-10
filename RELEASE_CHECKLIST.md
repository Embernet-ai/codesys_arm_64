# 🔥 CODESYS Control ARM32 — Release Checklist

> **Repository:** `Embernet-ai/codesys_arm_64`
> **Helm Chart:** `codesys-pod`
> **GitHub Pages:** `https://embernet-ai.github.io/codesys_arm_64/`

This checklist must be completed before every release of the CODESYS Control ARM32 Helm chart. Every box must be checked before merging to `main`.

---

## Pre-Release Verification

### 1. Version & Image Verification

- [ ] `charts/codesys-pod/Chart.yaml` → `version` has been bumped (current: `1.1.0`)
- [ ] `charts/codesys-pod/Chart.yaml` → `appVersion` matches the latest stable CODESYS release
- [ ] `charts/codesys-pod/values.yaml` → `installerUrl` matches the version in `appVersion`
- [ ] `catalog.cattle.io/upstream-version` annotation in `Chart.yaml` matches `appVersion`
- [ ] CODESYS installer package URL verified to exist:
  ```bash
  curl -sI "https://github.com/Embernet-ai/codesys_arm_64/releases/download/v<VERSION>/CODESYS.Control.for.Linux.ARM.32.bit.SL.<VERSION>.package" | head -1
  # Expected: HTTP/2 200 or 302 redirect
  ```
- [ ] Base image `debian:bullseye` verified for `amd64` and `arm64`:
  ```bash
  docker manifest inspect debian:bullseye
  ```

### 2. EmberNET Store Labels (The Big Four)

All four labels MUST appear on **pod template labels** AND **Service labels**.

| Label | Expected Value | Verified? |
|-------|---------------|-----------|
| `embernet.ai/store-app` | `"true"` | ☐ |
| `embernet.ai/gui-type` | `"web"` | ☐ |
| `embernet.ai/app-name` | `"codesys-pod"` | ☐ |
| `embernet.ai/gui-port` | `"8080"` | ☐ |

**Verification command:**
```bash
helm template test-release charts/codesys-pod | grep -c "embernet.ai/"
# Expected: 8 (4 labels × 2 resources: service + pod template)
```

- [ ] Labels present on pod template (deployment.yaml via `codesys-pod.storeLabels` helper)
- [ ] Labels present on Service (service.yaml via `codesys-pod.storeLabels` helper)
- [ ] Labels generated via `codesys-pod.storeLabels` helper (NOT hardcoded)

### 3. Network Configuration

- [ ] `network.hostNetwork: true` is the **default** in `values.yaml`
- [ ] Deployment renders `hostNetwork: true` + `dnsPolicy: ClusterFirstWithHostNet` by default
- [ ] Deployment renders `dnsPolicy: ClusterFirst` when `hostNetwork: false`
- [ ] `hostPort` is set on all ports (1217, 4840, 8080) when `hostNetwork: true`
- [ ] `hostPort` is absent when `hostNetwork: false`

**Verification:**
```bash
# Default (hostNetwork: true)
helm template test-release charts/codesys-pod | grep -E "hostNetwork|dnsPolicy|hostPort"

# Override (hostNetwork: false)
helm template test-release charts/codesys-pod --set network.hostNetwork=false | grep -E "hostNetwork|dnsPolicy|hostPort"
```

### 4. Service Configuration

- [ ] Service type is `ClusterIP` (default)
- [ ] Service name uses `{{ include "codesys-pod.fullname" . }}` helper
- [ ] Service selector uses `{{ include "codesys-pod.selectorLabels" . }}`
- [ ] `nodeSelector: {}` exists in values.yaml and is wired into Deployment
- [ ] Service exposes all three ports: gateway (1217), opcua (4840), webvisu (8080)

### 5. Sidecar Proxy Decision

CODESYS WebVisu is a **server-rendered HTML5 HMI** (not a complex SPA).

| Criterion | Assessment |
|-----------|------------|
| Has web UI? | ✅ Yes — WebVisu on port 8080 |
| Is an SPA? | ❌ No — server-rendered HTML5 |
| Absolute asset paths? | ⚠️ Evaluate — `/webvisu.htm` likely uses relative |
| Has root_url config? | ❌ No — no configurable base path |
| **Verdict** | **NO sidecar by default** — enable if WebVisu breaks through Dashboard proxy |

- [ ] Confirmed: `sidecarProxy.enabled: false` is default
- [ ] Confirmed: `configmap-sidecar-proxy.yaml` template only renders when enabled
- [ ] Confirmed: When sidecar enabled, `gui-port` switches to sidecar `listenPort` (8081)
- [ ] Confirmed: `gui.type` defaults to `"web"`

### 6. Chart Linting & Templating

- [ ] `helm lint charts/codesys-pod` passes clean (0 errors)
- [ ] `helm template test-release charts/codesys-pod` renders without errors
- [ ] `helm template test-release charts/codesys-pod --set network.hostNetwork=false` renders without errors
- [ ] `helm template test-release charts/codesys-pod --set sidecarProxy.enabled=true` renders without errors
- [ ] `helm template test-release charts/codesys-pod --set persistence.enabled=false` renders without errors

---

## CI/CD Pipeline Validation

### 7. GitHub Actions Workflow

- [ ] `.github/workflows/helm-publish.yml` exists
- [ ] Triggers on push to `main` with path filter `charts/**`
- [ ] Includes `workflow_dispatch:` for manual triggers
- [ ] Uses `azure/setup-helm@v4`
- [ ] Uses `peaceiris/actions-gh-pages@v4`
- [ ] Packages chart from `charts/codesys-pod` directory
- [ ] Indexes with correct URL: `https://embernet-ai.github.io/codesys_arm_64/`
- [ ] Has lint job that runs before publish job

### 8. Helm Repository Verification

After the workflow runs:

- [ ] `gh-pages` branch updated with new `.tgz` package
- [ ] `index.yaml` on `gh-pages` contains the new version entry
- [ ] URLs in `index.yaml` are **absolute** (not relative)
- [ ] Repository is fetchable:
  ```bash
  helm repo add codesys-test https://embernet-ai.github.io/codesys_arm_64/
  helm repo update
  helm search repo codesys-test
  ```
- [ ] Chart version in index matches `Chart.yaml` version

---

## Industrial Dashboard Integration

### 9. Dashboard Discovery

- [ ] Dashboard can discover the deployed pod via `embernet.ai/store-app: "true"` label
- [ ] Dashboard shows "CODESYS Control ARM32" from `gui.displayName` value
- [ ] Dashboard renders the WebVisu in an iframe when the tile is clicked (`gui-type: "web"`)
- [ ] WebVisu is accessible at `http://<NODE-IP>:8080/webvisu.htm` (hostNetwork mode)

### 10. CODESYS-Specific Verification

- [ ] CODESYS Gateway port 1217 is reachable from CODESYS IDE
- [ ] OPC UA server on port 4840 responds to OPC UA client queries
- [ ] WebVisu on port 8080 renders the HMI correctly
- [ ] PLC runtime starts and accepts project downloads
- [ ] Persistence volume retains application data across pod restarts

---

## Post-Release Verification

### 11. Deployment Smoke Test

```bash
# Install the chart
helm install codesys charts/codesys-pod -n industrial --create-namespace

# Verify pod is running
kubectl get pods -n industrial -l app.kubernetes.io/name=codesys-pod

# Check container is ready (1/1)
kubectl get pods -n industrial -l embernet.ai/store-app=true

# Verify services
kubectl get svc -n industrial -l embernet.ai/store-app=true

# Verify labels on pod
kubectl get pods -n industrial -l embernet.ai/store-app=true -o jsonpath='{.items[0].metadata.labels}' | jq .

# Test WebVisu
curl -s http://<NODE-IP>:8080/webvisu.htm | head -10

# Test Gateway port
nc -zv <NODE-IP> 1217

# Test OPC UA port
nc -zv <NODE-IP> 4840
```

- [ ] Pod starts successfully (init container downloads and installs CODESYS)
- [ ] Main container healthy (CODESYS runtime running)
- [ ] PVCs are bound (persistence enabled by default)
- [ ] Event log shows no warnings or errors

### 12. Functional Verification

- [ ] CODESYS IDE can connect via Gateway port 1217
- [ ] PLC project can be downloaded to runtime
- [ ] WebVisu displays runtime HMI correctly
- [ ] OPC UA Server responds to client connections on port 4840
- [ ] Runtime data persists across pod restarts (via PVC)
- [ ] Resource usage is within expected limits (1Gi RAM, 1 CPU)

---

## Rancher Catalog Annotations Verification

- [ ] `catalog.cattle.io/display-name` is `"CODESYS Control ARM32"`
- [ ] `catalog.cattle.io/release-name` is `"codesys-pod"`
- [ ] `catalog.cattle.io/certified` is `"partner"`
- [ ] `catalog.cattle.io/namespace` is `"industrial"`
- [ ] `catalog.cattle.io/os` is `"linux"`
- [ ] `catalog.cattle.io/kube-version` is `">=1.19.0-0"`
- [ ] `catalog.cattle.io/rancher-version` is `">=2.5.0-0"`
- [ ] `catalog.cattle.io/upstream-version` matches `appVersion`
- [ ] `catalog.cattle.io/arch` includes `"arm64,amd64"`

---

## Rollback Protocol

If the release introduces regressions:

1. **Revert the commit** on `main` branch
2. **CI/CD will republish** the previous chart version to GitHub Pages
3. **On-cluster rollback:**
   ```bash
   helm rollback codesys -n industrial
   ```
4. **Document the issue** in a GitHub Issue with:
   - Chart version that failed
   - Error logs and symptoms
   - Steps to reproduce

---

## Sign-Off

| Field | Value |
|-------|-------|
| Chart Version | `1.1.0` |
| App Version | `4.20.0.0` |
| Base Image | `debian:bullseye` |
| Released By | _______________ |
| Release Date | _______________ |
| Dashboard Verified | ☐ Yes / ☐ No |
| Sidecar Needed | ☐ No (server-rendered WebVisu — evaluate if breaks through proxy) |

---

**🔥 Fireball Industries** — *Ignite Your Factory Efficiency*
