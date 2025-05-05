#!/bin/bash

set -e

METALLB_IP_RANGE="192.168.0.80-192.168.0.99"
PODINFO_HOST="info.int.rosair.au"
PODINFO_URL="https://${PODINFO_HOST}"

echo "🔍 Checking MetalLB assigned IPs..."
kubectl get svc -A | grep -E 'LoadBalancer|EXTERNAL-IP' || echo "❌ No LoadBalancer services found."

echo
echo "🌐 Verifying ingress-nginx service..."
kubectl get svc -n ingress-nginx ingress-nginx-controller || echo "❌ ingress-nginx service not found"

echo
echo "🧠 Checking if DNS resolves $PODINFO_HOST..."
if dig +short "$PODINFO_HOST" | grep -qE '^[0-9]+\.'; then
  echo "✅ DNS resolution working"
else
  echo "❌ DNS resolution failed (check /etc/hosts or EdgeRouter DNS override)"
fi

echo
echo "📡 Attempting curl to $PODINFO_URL ..."
curl -s -o /dev/null -w "HTTP status: %{http_code}\n" "$PODINFO_URL" || echo "❌ Curl failed — could be TLS, DNS, or Ingress issue"

echo
echo "📦 Checking cert-manager Certificates..."
kubectl get certificate -A || echo "⚠️  No certificates found — cert-manager may not be issuing yet"

echo
echo "🔏 Checking Sealed Secrets controller pod..."
kubectl get pods -n sealed-secrets | grep sealed-secrets || echo "❌ Sealed Secrets pod not running"

echo
echo "✅ Health check complete."
