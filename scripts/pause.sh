#!/usr/bin/env bash
# Stop compute resources outside study hours to conserve credits
set -euo pipefail
RG="rg-nsp-platform-dev"
AKS=$(az aks list -g "$RG" --query '[0].name' -o tsv 2>/dev/null || echo "aks-nsp-core-dev")

echo "Stopping AKS cluster: $AKS..."
az aks stop -g "$RG" -n "$AKS" --no-wait || true

SRV=$(az postgres flexible-server list -g "$RG" --query '[0].name' -o tsv 2>/dev/null || true)
if [ -n "$SRV" ]; then
  echo "Stopping PostgreSQL server: $SRV..."
  az postgres flexible-server stop -g "$RG" -n "$SRV" --no-wait || true
fi
echo "Cluster and database stopping. Re-run scripts/resume.sh to restart."
