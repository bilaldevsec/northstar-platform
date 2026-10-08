#!/usr/bin/env bash
set -u
set +H

echo "================================================================="
echo "  NORTHSTAR PAY: AUDIT REMEDIATION & VERIFICATION SWEEP"
echo "================================================================="

echo -e "\n=== 1. DIAGNOSE PENDING WAF POD & NODE STATE ==="
kubectl get nodes -o wide
kubectl -n nsp-edge describe pod waf-c59ff68ff-p44kz | tail -n 20 2>&1 || true
kubectl get pods -A --no-headers | wc -l
az aks nodepool list -g rg-nsp-platform-dev --cluster-name aks-nsp-core-dev -o table
az vm list-usage -l southeastasia -o table | grep -E 'Total Regional|Standard B' || true

echo -e "\n=== 2. RESOLVE WAF ROLLOUT & EXECUTE ATTACK PROBE ==="
echo "Deleting legacy pod to release node allocation..."
kubectl -n nsp-edge delete pod waf-6d668849d7-qbn4x --now 2>/dev/null || true
echo "Waiting for new WAF pod rollout..."
kubectl -n nsp-edge rollout status deploy/waf --timeout=120s

NEW_WAF=$(kubectl -n nsp-edge get pod -l app=waf -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
echo "Active WAF pod: $NEW_WAF"
if [ -n "$NEW_WAF" ]; then
  echo "Probing /health (Expected: 200)..."
  kubectl -n nsp-edge exec "$NEW_WAF" -c waf -- curl -s -o /dev/null -w "Health Check HTTP Code: %{http_code}\n" http://127.0.0.1:8080/health || true

  echo "Probing SQL Injection Attack (Expected: 403)..."
  kubectl -n nsp-edge exec "$NEW_WAF" -c waf -- curl -s -o /dev/null -w "Attack Probe HTTP Code: %{http_code}\n" "http://127.0.0.1:8080/?q=%27%20OR%201%3D1--" || true
fi
kubectl get httproute,gateway -A 2>&1 || true

echo -e "\n=== 3. PROVE SECRET ZERO IN-MEMORY MOUNT (-c api) ==="
kubectl -n nsp-prod exec deploy/orders-api -c api -- ls -la /mnt/secrets
kubectl -n nsp-prod exec deploy/orders-api -c api -- sh -c 'mount | grep -i secrets'

echo -e "\n=== 4. LOCK DOWN DR STORAGE VAULT & TEST ENTRA ACCESS ==="
az storage account update -g rg-nsp-dr-dev -n stnspdr1276143 \
  --allow-shared-key-access false \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --default-action Deny \
  --bypass AzureServices -o none

AKS_PIP_ID=$(az aks show -g rg-nsp-platform-dev -n aks-nsp-core-dev --query 'networkProfile.loadBalancerProfile.effectiveOutboundIPs[0].id' -o tsv 2>/dev/null || echo "")
if [ -n "$AKS_PIP_ID" ]; then
  AKS_EGRESS_IP=$(az network public-ip show --ids "$AKS_PIP_ID" --query ipAddress -o tsv 2>/dev/null || echo "")
  [ -n "$AKS_EGRESS_IP" ] && az storage account network-rule add -g rg-nsp-dr-dev -n stnspdr1276143 --ip-address "$AKS_EGRESS_IP" -o none 2>/dev/null || true
fi

MY_IP=$(curl -s https://ifconfig.me 2>/dev/null || echo "")
[ -n "$MY_IP" ] && az storage account network-rule add -g rg-nsp-dr-dev -n stnspdr1276143 --ip-address "$MY_IP" -o none 2>/dev/null || true

az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Storage Blob Data Reader" \
  --scope $(az storage account show -g rg-nsp-dr-dev -n stnspdr1276143 --query id -o tsv) -o none 2>/dev/null || true

echo "Triggering backup test job under network lockdown..."
kubectl -n nsp-prod delete job test-after-lockdown 2>/dev/null || true
kubectl -n nsp-prod create job --from=cronjob/db-backup test-after-lockdown
kubectl -n nsp-prod wait --for=condition=complete job/test-after-lockdown --timeout=90s 2>&1 || kubectl -n nsp-prod describe job test-after-lockdown | tail -n 15

echo -e "\n=== 5. ENFORCE GITHUB BRANCH PROTECTION (BOTH REPOS) ==="
gh api -X PUT repos/bilaldevsec/northstar-platform/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  --input - << 'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["validate (platform)", "validate (network)"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null
}
JSON

gh api -X PUT repos/bilaldevsec/northstar-apps/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  --input - << 'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null
}
JSON

echo "Verifying protection status on northstar-platform..."
gh api repos/bilaldevsec/northstar-platform/branches/main/protection --jq '{required_approvals: .required_pull_request_reviews.required_approving_review_count, status_checks: .required_status_checks.contexts}'

echo -e "\n=== 6. INSTALL COSIGN & VERIFY CRYPTOGRAPHIC PROVENANCE ==="
if ! command -v cosign >/dev/null 2>&1; then
  echo "Installing Cosign..."
  curl -sSL -o /tmp/cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
  chmod +x /tmp/cosign
  sudo mv /tmp/cosign /usr/local/bin/cosign
fi

echo "Authenticating to ACR..."
az acr login -n crnspcoredev8l2m0 --output none 2>/dev/null || true

echo "Test 6A: Positive Verification on Signed Production Digest..."
cosign verify crnspcoredev8l2m0.azurecr.io/orders-api@sha256:9e824abcb54c1f4d70b108556a47b096aaa020759b6418aa992b2e0e03095d80 \
  --certificate-identity-regexp '^https://github.com/bilaldevsec/northstar-apps/\.github/workflows/ci\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com 2>&1 | head -n 15

echo -e "\nTest 6B: Negative Verification on Unsigned Public Digest (Expected: Failure)..."
cosign verify docker.io/library/alpine:latest \
  --certificate-identity-regexp '^https://github.com/bilaldevsec/northstar-apps/\.github/workflows/ci\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com 2>&1 | grep -iE "error|no matching signatures" || true

echo -e "\n=== REMEDIATION EXECUTION COMPLETE ==="
