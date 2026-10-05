# NorthStar Pay - Enterprise DevSecOps Guardrails

## Cloud & Architecture Rules
- Target Provider: Azure (azurerm ~> 4.0)
- Target Region: southeastasia (Strictly enforced by subscription policy)
- Naming Convention: <resource_type>-nsp-<workload>-<env>
- State Storage: Remote Azure Blob backend in resource group 'rg-nsp-tfstate' on account 'stnsptfstate28354'

## Network Security Rules
- All PaaS services (Key Vault, PostgreSQL, Storage) must use Private Endpoints. Public access disabled.
- Subnet-level NSGs must explicitly override Azure's default 'AllowVnetInBound' (priority 65000) with a 'DenyAll' rule at priority 4096.
- Database subnet (snet-data) only accepts incoming traffic on port 5432 from the AKS subnet (10.1.0.0/24).

## Identity Rules
- No hardcoded secrets, passwords, or access keys.
- Authentication to Azure from pipelines must strictly use OpenID Connect (OIDC) Workload Identity Federation.
