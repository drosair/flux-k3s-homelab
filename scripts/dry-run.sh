#!/bin/bash

echo "🔍 Checking for existing Flux Kustomizations..."
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A

echo
echo "🔍 Checking for existing GitRepositories..."
kubectl get gitrepositories.source.toolkit.fluxcd.io -A

echo
echo "🔍 Checking for HelmReleases (optional)..."
kubectl get helmreleases.helm.toolkit.fluxcd.io -A

echo
echo "🔍 Checking if 'flux-system' namespace exists..."
if kubectl get ns flux-system &>/dev/null; then
  echo "✅ 'flux-system' namespace exists. Flux is already bootstrapped."
else
  echo "ℹ️  'flux-system' namespace not found. Safe to bootstrap fresh."
fi

echo
echo "🧼 If you want to fully reset Flux, run the following:"
echo "kubectl delete kustomization --all -n flux-system"
echo "kubectl delete gitrepository --all -n flux-system"
echo "kubectl delete helmrelease --all -n flux-system  # Optional"
echo "kubectl delete namespace flux-system"

echo
echo "💡 You can now re-run 'flux bootstrap' when ready."
