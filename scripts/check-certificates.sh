#!/bin/bash
echo "🔐 TLS Certificate Status Across Namespaces"
echo "------------------------------------------"
kubectl get certificate --all-namespaces -o json | jq -r '
.items[] | 
[
  .metadata.namespace, 
  .metadata.name, 
  (.spec.dnsNames | join(",")), 
  .spec.issuerRef.name,
  (.status.conditions[]? | select(.type == "Ready") | .status), 
  .status.notAfter
] | @tsv' | column -t -s $'\t' | sort
