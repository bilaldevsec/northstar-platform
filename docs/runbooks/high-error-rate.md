# Runbook: OrdersApiErrorBudgetFastBurn
Owner: platform-team | Severity: SEV2
## What this means: The orders-api is returning 5xx errors at a rate that will exhaust the monthly error budget in hours.
## First 5 minutes:
1. Check Grafana 'Traffic & Errors' panel.
2. Identify if failures are isolated to one pod: `kubectl -n nsp-prod get pods`
3. Check logs: `kubectl -n nsp-prod logs deploy/orders-api --tail=100 | grep "500"`
## Likely causes: Bad release (rollback via ArgoCD), DB connection drop (check NSG), Key Vault secret expired.
