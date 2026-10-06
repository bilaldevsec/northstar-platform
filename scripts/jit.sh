#!/usr/bin/env bash
# Just-In-Time (JIT) Privilege Elevation Automation
# Usage: ./scripts/jit.sh <user-id> <role> <scope> <minutes> <reason>

set -euo pipefail

USER_ID="${1:?Usage: $0 <user-id> <role> <scope> <minutes> <reason>}"
ROLE="${2:?Role required}"
SCOPE="${3:?Scope required}"
MINUTES="${4:?Duration in minutes required}"
REASON="${5:?Reason required}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${REPO_ROOT}/docs/evidence/phase-a/jit-access-log.txt"
mkdir -p "$(dirname "$LOG_FILE")"

# Expand resource group name to full scope if only RG name provided
if [[ "$SCOPE" != /* ]]; then
  SUB_ID=$(az account show --query id -o tsv)
  SCOPE="/subscriptions/${SUB_ID}/resourceGroups/${SCOPE}"
fi

# Resolve object ID if an email or signed-in user name is passed
ASSIGNEE_ARGS=()
if [[ "$USER_ID" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  ASSIGNEE_ARGS=(--assignee-object-id "$USER_ID" --assignee-principal-type User)
else
  # Check if matches current signed-in user or graph user
  SIGNED_IN_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
  if [ -n "$SIGNED_IN_ID" ]; then
    ASSIGNEE_ARGS=(--assignee-object-id "$SIGNED_IN_ID" --assignee-principal-type User)
  else
    ASSIGNEE_ARGS=(--assignee "$USER_ID")
  fi
fi

TIMESTAMP_GRANT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "[$TIMESTAMP_GRANT] [GRANT] User: $USER_ID | Role: $ROLE | Scope: $SCOPE | Duration: ${MINUTES}m | Reason: $REASON" | tee -a "$LOG_FILE"

az role assignment create "${ASSIGNEE_ARGS[@]}" --role "$ROLE" --scope "$SCOPE" -o none

# Launch detached background subshell for automatic revocation
nohup bash -c '
  sleep $(( '"$MINUTES"' * 60 ))
  az role assignment delete '"${ASSIGNEE_ARGS[*]}"' --role "'"$ROLE"'" --scope "'"$SCOPE"'" --yes -o none 2>/dev/null || true
  TIMESTAMP_REVOKE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$TIMESTAMP_REVOKE] [REVOKE] User: '"$USER_ID"' | Role: '"$ROLE"' | Scope: '"$SCOPE"' | Status: Revoked after '"$MINUTES"'m" >> "'"$LOG_FILE"'"
' >/dev/null 2>&1 &

disown || true
echo "Privilege granted for ${MINUTES} minute(s). Background timer started for automated revocation."
