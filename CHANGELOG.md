# Changelog — codesys-pod (ARM32)

All notable changes to the CODESYS Control ARM32 Helm chart.

---

## [1.3.0] — 2026-04-15

### Changed
- **Sidecar proxy hardened:** Switched from `nginx:1.25-alpine` to `nginxinc/nginx-unprivileged:1.27-alpine`
  - Prevents crash when running with `readOnlyRootFilesystem: true` + `runAsNonRoot: true`
  - Added writable tmpfs volumes: `/var/cache/nginx`, `/var/run`
- **Deployment strategy:** Added `strategy.type: Recreate` to prevent PVC mount conflicts during rolling updates
- **README corrections:** Fixed stale defaults (service type now `ClusterIP`, installer URL now `v4.20.0.0`)
- **Release checklist:** Updated sign-off to v1.3.0, added sidecar image field

### No Change
- App version remains `4.20.0.0` (latest stable CODESYS Control ARM SL)
- Base image remains `debian:bullseye`
- All EmberNET store labels unchanged (4 on pod, 4 on service)
- Sidecar proxy remains disabled by default (WebVisu is server-rendered)

---

## [1.2.0] — 2026-04-14

### Added
- Full EmberNET template alignment
- EmberNET Store Labels (The Big Four) on pod and service
- Sidecar proxy support (disabled by default)
- `configmap-sidecar-proxy.yaml` with CODESYS WebVisu-specific rewrite rules
- `RELEASE_CHECKLIST.md` — production release protocol
- `network.hostNetwork: true` as default (OT platform requirement)
- `dnsPolicy` conditional (ClusterFirstWithHostNet vs ClusterFirst)
- `hostPort` on all three ports when `hostNetwork: true`
- Dynamic `gui-port` label switching for sidecar proxy
- CODESYS-specific sidecar rewrite rules for `/webvisu` paths

### Changed
- Service type from `LoadBalancer` to `ClusterIP` (EmberNET standard)
- Chart description updated for clarity
- Catalog annotations expanded (namespace, kube-version, rancher-version, upstream-version)
- Icon URL updated to GitHub-hosted PNG

---

## [1.0.3] — 2026-01-26

### Added
- Initial Helm chart with installer pattern
- initContainer downloads CODESYS `.package` from GitHub Releases
- Three-port service: Gateway (1217), OPC UA (4840), WebVisu (8080)
- PVC for `/var/opt/codesys` data persistence

---

## [1.0.2] — 2026-01-26

### Added
- Initial release

---

**🔥 Fireball Industries** — *Ignite Your Factory Efficiency*
