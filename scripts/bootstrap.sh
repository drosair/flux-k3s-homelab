#!/bin/bash

echo "📦 Installing MetalLB CRDs..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_ipaddresspools.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_l2advertisements.yaml

echo "✅ MetalLB CRDs installed. Now run your 'flux bootstrap' command."
