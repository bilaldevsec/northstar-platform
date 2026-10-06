#!/bin/bash
set -euo pipefail

# Source environment
source ~/.nsp_env

RG="rg-nsp-ci"
REPO="bilaldevsec/northstar-platform"

echo "Creating Resource Group: $RG in $REGION"
az group create --name "$RG" --location "$REGION" --output none

echo "Creating user-assigned managed identities..."
az identity create --name id-nsp-gh-plan --resource-group "$RG" --location "$REGION" --output none
az identity create --name id-nsp-gh-apply --resource-group "$RG" --location "$REGION" --output none

echo "Creating federated credentials..."
az identity federated-credential create \
  --name cred-plan \
  --identity-name id-nsp-gh-plan \
  --resource-group "$RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${REPO}:pull_request" \
  --audiences "api://AzureADTokenExchange" \
  --output none

az identity federated-credential create \
  --name cred-apply \
  --identity-name id-nsp-gh-apply \
  --resource-group "$RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${REPO}:environment:prod" \
  --audiences "api://AzureADTokenExchange" \
  --output none

echo "Retrieving Principal IDs..."
PLAN_PRINCIPAL_ID=$(az identity show --name id-nsp-gh-plan --resource-group "$RG" --query principalId -o tsv)
APPLY_PRINCIPAL_ID=$(az identity show --name id-nsp-gh-apply --resource-group "$RG" --query principalId -o tsv)

echo "Waiting for Principal IDs to propagate..."
sleep 15

echo "Assigning Reader role to id-nsp-gh-plan..."
az role assignment create \
  --role "Reader" \
  --assignee-object-id "$PLAN_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUB" \
  --output none

echo "Assigning Contributor role to id-nsp-gh-apply..."
az role assignment create \
  --role "Contributor" \
  --assignee-object-id "$APPLY_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUB" \
  --output none

echo "Assigning Role Based Access Control Administrator role to id-nsp-gh-apply..."
az role assignment create \
  --role "Role Based Access Control Administrator" \
  --assignee-object-id "$APPLY_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUB" \
  --output none

echo "Retrieving Client IDs..."
PLAN_CLIENT_ID=$(az identity show --name id-nsp-gh-plan --resource-group "$RG" --query clientId -o tsv)
APPLY_CLIENT_ID=$(az identity show --name id-nsp-gh-apply --resource-group "$RG" --query clientId -o tsv)

echo ""
echo "==== CLIENT IDS ===="
echo "PLAN_CLIENT_ID=${PLAN_CLIENT_ID}"
echo "APPLY_CLIENT_ID=${APPLY_CLIENT_ID}"
echo "===================="
