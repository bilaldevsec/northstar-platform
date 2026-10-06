#!/usr/bin/env bash
# usage: ./rotate-db-password.sh
set -euo pipefail

RG="rg-nsp-platform-dev"
KV="kv-nsp-plat-dev-8l2m0"
SRV=$(az postgres flexible-server list -g "$RG" --query '[0].name' -o tsv 2>/dev/null || echo "")

if [ -z "$SRV" ]; then
  echo "PostgreSQL server not found in $RG, checking rg-nsp-platform-prod..."
  RG="rg-nsp-platform-prod"
  SRV=$(az postgres flexible-server list -g "$RG" --query '[0].name' -o tsv)
fi

NEW_PASS="$(openssl rand -base64 24 | tr -d '/+=')"
TIMESTAMP=$(date -u +%FT%TZ)
echo "[$TIMESTAMP] Starting automated password rotation for $SRV..." | tee -a docs/evidence/phase-h/rotation-log.txt

echo "Step 1: Updating PostgreSQL Flexible Server admin password..."
az postgres flexible-server update -g "$RG" -n "$SRV" --admin-password "$NEW_PASS" -o none

echo "Step 2: Updating Key Vault secret..."
az keyvault secret set --vault-name "$KV" --name db-password --value "$NEW_PASS" -o none

echo "Step 3: Triggering rolling restart of orders-api pods to pick up secret..."
kubectl -n nsp-prod rollout restart deploy/orders-api
kubectl -n nsp-prod rollout status deploy/orders-api --timeout=120s

echo "[$TIMESTAMP] Secret rotation completed successfully." | tee -a docs/evidence/phase-h/rotation-log.txt
