# flux-k3s-homelab

This is a GitOps-based Kubernetes home-lab using [FluxCD](https://fluxcd.io), Helm, and MetalLB, running on lightweight K3s clusters (e.g., Colima, MacBook Pro, Mac Mini, QNAP, etc.).

## ✅ Features

- FluxCD GitOps setup
- Helm-based app deployment (no Kustomize overlays)
- Modular folder structure per app/infra component
- Ingress-NGINX + Cert-Manager + Sealed-Secrets
- Internal routing via MetalLB (192.168.0.80–99)
- DNS routed via EdgeRouter `dnsmasq`
- Optional external access via Cloudflare Tunnel

---

## 📁 Folder Structure

```
clusters/homelab/
├── apps/               # Each app (e.g. podinfo, plex, sonarr)
├── infra/              # Core services (ingress, cert-manager, metallb, etc.)
├── flux-system/        # Created by Flux bootstrap
├── apps.yaml           # Flux Kustomization (suspended by default)
├── infra.yaml          # Active Flux Kustomization for infra
└── info.yaml           # Individual Kustomization for podinfo
```

---

## 🧪 Requirements

- Kubernetes cluster (K3s or Colima recommended)
- GitHub repository (for Flux sync)
- Ingress controller IP assigned via MetalLB
- EdgeRouter or LAN DNS override for `.int.rosair.au`

---

## 🚀 Install Instructions

1. **Install CRDs (required before Flux bootstraps)**

MetalLB requires CRDs to be pre-installed once:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_ipaddresspools.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_l2advertisements.yaml
```

👉 This is handled automatically via [`bootstrap.sh`](./bootstrap.sh) if you prefer.

2. **Bootstrap Flux (GitHub example)**

```bash
flux bootstrap github   --owner=drosair   --repository=flux-k3s-homelab   --branch=main   --path=clusters/homelab   --personal
```

3. **Monitor status**

```bash
flux get kustomizations --all-namespaces
flux get helmreleases -A
```

---

## 🌐 Example Ingress Access

Ensure your router has DNS override:

```
address=/.int.rosair.au/192.168.0.81
```

Then open:

```
http://info.int.rosair.au
```

---

## 🔒 Secrets

Use `kubeseal` and store encrypted secrets under `clusters/homelab/secrets/`.

