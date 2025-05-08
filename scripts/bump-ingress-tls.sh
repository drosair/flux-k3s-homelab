#!/bin/bash

# Hardcoded for your homelab setup
NAMESPACE="info"
INGRESS_NAME="podinfo"

echo "🔁 Forcing TLS re-issue by updating annotation on Ingress '$INGRESS_NAME' in namespace '$NAMESPACE'..."
kubectl annotate ingress "$INGRESS_NAME" -n "$NAMESPACE" \
  homelab.io/force-tls-reissue=$(date +%s) --overwrite
