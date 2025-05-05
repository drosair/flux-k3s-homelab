K3s GitOps Homelab Cheatsheet
=============================

🔁 FluxCD: Reconciliation Commands
---------------------------------
flux reconcile kustomization flux-system --with-source
flux reconcile kustomization infra --with-source
flux reconcile kustomization info --with-source
flux reconcile kustomization secrets --with-source

Check status:
flux get kustomizations
flux get helmreleases -A

🔐 TLS and cert-manager Checks
------------------------------
Get all certs:
kubectl get certificate -A

Describe a certificate:
kubectl describe certificate info-tls -n info

Check CertificateRequest activity:
kubectl get certificaterequest -A

💥 Delete stuck cert:
kubectl delete certificate info-tls -n info
kubectl delete secret info-tls -n info

Then reconcile:
flux reconcile kustomization info --with-source

📡 DNS / Ingress / Networking
-----------------------------
Check DNS:
dig info.int.rosair.me +short

Check MetalLB LoadBalancer IPs:
kubectl get svc -A | grep LoadBalancer

Check Ingress:
kubectl get ingress -A

🛠 TLS Ingress Bump
-------------------
Use this script to force cert-manager to re-process an Ingress:
./scripts/bump-ingress-tls.sh

✅ Ensure Ingress annotations include:
cert-manager.io/cluster-issuer: letsencrypt-cloudflare
