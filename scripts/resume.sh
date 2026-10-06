#!/usr/bin/env bash
# Resume platform services
set -euo pipefail
RG="rg-nsp-platform-dev"
AKS=$(az aks list -g "$RG" --query '[0].name' -o tsv 2>/dev/null || echo "aks-nsp-core-dev")

SRV=$(az postgres flexible-server list -g "$RG" --query '[0].name' -o tsv 2>/dev/null || true)
if [ -n "$SRV" ]; then
  echo "Starting PostgreSQL server: $SRV..."
  az postgres flexible-server start -g "$RG" -n "$SRV" || true
fi

echo "Starting AKS cluster: $AKS..."
az aks start -g "$RG" -n "$AKS"
kubectl get nodes
