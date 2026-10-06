#!/usr/bin/env bash
set -uo pipefail
D="docs/evidence/$(date -u +%F)"; mkdir -p "$D"
az role assignment list --all --include-inherited -o json > "$D/c01-role-assignments.json" || true
az network nsg list -o json > "$D/c07-nsgs.json" || true
( cd "$D" && sha256sum * > SHA256SUMS ) || true
echo "Evidence collected to $D"
