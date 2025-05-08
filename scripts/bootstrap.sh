#!/bin/bash

set -e

echo "📦 Installing MetalLB CRDs..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_ipaddresspools.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_l2advertisements.yaml

echo "📦 Installing cert-manager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.crds.yaml

echo "📦 Installing Sealed Secrets CRDs only..."
curl -sL https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.25.0/controller.yaml | \
  yq e 'select(.kind == "CustomResourceDefinition")' - | \
  kubectl apply -f -

echo "✅ All CRDs installed"