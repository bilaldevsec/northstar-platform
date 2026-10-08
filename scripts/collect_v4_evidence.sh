set +H

echo "=== 1. SECRET ZERO VERIFICATION ==="
kubectl get secret -n nsp-prod
kubectl -n nsp-prod get secretproviderclass -o yaml
ORDERS_POD=$(kubectl -n nsp-prod get pods -l app=orders-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$ORDERS_POD" ]; then
  kubectl -n nsp-prod exec "$ORDERS_POD" -c orders-api -- ls -la /mnt/secrets 2>&1 || echo "Mount /mnt/secrets not accessible"
else
  echo "No orders-api pod found"
fi

echo -e "\n=== 2. UNFILTERED AZURE POLICY ASSIGNMENTS ==="
az policy assignment list --query "[].{Name:name, DisplayName:displayName, Scope:scope, EnforcementMode:enforcementMode}" -o table

echo -e "\n=== 3 & 4. WAF DEPLOYMENT CONFIG & ROLLOUT DIAGNOSTICS ==="
kubectl -n nsp-edge get deploy waf -o jsonpath='{.spec.template.spec.containers[0].env}' | jq . 2>/dev/null || kubectl -n nsp-edge get deploy waf -o yaml | grep -A8 "env:"
kubectl -n nsp-edge describe deploy waf | tail -n 25
kubectl -n nsp-edge get pods -l app=waf -o wide
WAF_POD=$(kubectl -n nsp-edge get pods -l app=waf -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$WAF_POD" ]; then
  kubectl -n nsp-edge describe pod "$WAF_POD" | grep -E "State:|Reason:|Message:|Warning|Events:" -A 10
fi
kubectl top pods -n nsp-edge 2>&1 || echo "Metrics-server not reporting pod metrics"

echo -e "\n=== 6. DR STORAGE NETWORK & SHARED KEY ACCESS ==="
az storage account show -g rg-nsp-dr-dev -n stnspdr1276143 --query "{publicNetworkAccess:publicNetworkAccess, allowSharedKeyAccess:allowSharedKeyAccess, defaultAction:networkRuleSet.defaultAction}" -o json

echo -e "\n=== 7. KEY VAULT CLI ACCESS FROM LOCAL WORKSTATION ==="
find ~/projects -name "*rotate*db*" -type f -exec head -n 30 {} + 2>/dev/null || echo "Rotation script not found"
az keyvault secret set --vault-name kv-nsp-plat-dev-8l2m0 --name "audit-kv-test" --value "probe" 2>&1 || true

echo -e "\n=== 8. KEYLESS COSIGN PROMOTION VERIFICATION ==="
if command -v cosign >/dev/null 2>&1; then
  cosign verify \
    --certificate-identity-regexp "https://github.com/bilaldevsec/.*" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    crnspcoredev8l2m0.azurecr.io/orders-api@sha256:9e824abcb54c1f4d70b108556a47b096aaa020759b6418aa992b2e0e03095d80 2>&1 || true
else
  echo "Cosign binary not found locally on PATH"
fi
