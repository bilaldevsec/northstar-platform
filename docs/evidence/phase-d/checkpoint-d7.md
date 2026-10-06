# Phase D.7 Platform Checkpoint Report: Security & Isolation Verification

**Date:** 2026-10-06  
**Target Environment:** NorthStar Platform Core Dev / Prod  
**Cluster:** aks-nsp-core-dev / aks-nsp-prod-sea-01  
**Auditor / Operator:** @bilaldevsec  

---

## 1. Executive Summary
This document serves as the formal Phase D.7 Platform Checkpoint Report confirming zero-trust network isolation, identity-driven access controls, PaaS perimeter enforcement, and Kubernetes runtime hardening across the NorthStar platform.

---

## 2. Platform Control Assertions & Evidence

### 2.1 Database Private Isolation
- **Configuration:** Azure Database for PostgreSQL Flexible Server is deployed into a private delegated subnet `snet-data` (`10.1.1.0/24`) within the spoke virtual network (`vnet-nsp-spoke-dev`).
- **Endpoint Exposure:** Public network access is strictly disabled (`publicNetworkAccess = Disabled`).
- **Resolution & Routing:** Only accessible via private DNS zone `privatelink.postgres.database.azure.com` and spoke VNet peering; zero inbound Internet route exists.

### 2.2 Key Vault Private Link Isolation
- **Configuration:** Azure Key Vault (`kv-nsp-plat-dev-8l2m0`) utilizes an Azure Private Endpoint residing in `snet-private-endpoints` (`10.1.2.0/24`).
- **DNS Resolution Proof:** Internal cluster resolution via CoreDNS:
  ```text
  Name:    kv-nsp-plat-dev-8l2m0.privatelink.vaultcore.azure.net
  Address: 10.1.2.4
  ```
- **Access Boundary:** Public network access is disabled/bypassed only by approved Azure trusted services.

### 2.3 Storage Shared Key Authentication Disabled
- **Configuration:** Storage accounts enforce `sharedKeyAccess = false`.
- **Enforcement:** Shared Access Signature (SAS) tokens and storage account keys are blocked at the control plane and data plane.
- **Authentication Model:** Exclusively governed via Microsoft Entra ID (formerly Azure AD) OAuth2 tokens and Azure RBAC (Storage Blob Data Contributor/Reader).

### 2.4 AKS Identity Architecture
- **Control-Plane Authentication:** Microsoft Entra ID authentication with Kubernetes RBAC integrated.
- **Local Accounts:** Local admin accounts are disabled (`disable-local-accounts = true`), eliminating static kubeconfig credential risks.
- **Workload Identity:** Azure AD Workload Identity and OIDC Issuer are enabled. Kubernetes ServiceAccounts federate directly with managed identities without long-lived secret rotation.

### 2.5 Kubernetes Pod Security Standards (PSS)
- **Profile Enforcement:** The `restricted` Pod Security Standard is actively enforced on application namespaces (e.g., `nsp-prod`).
- **Hardening Rules:**
  - `allowPrivilegeEscalation: false`
  - Linux capability drops: `ALL`
  - Root execution disabled: `runAsNonRoot: true`
  - Mandatory Seccomp Profile: `RuntimeDefault`

### 2.6 Perimeter WAF & Telemetry Protection
- **Metrics Exposure:** Internal telemetry (`/metrics`) endpoints are excluded from the public Gateway API / Envoy edge listeners (`docs/evidence/phase-d/metrics-waf-block.txt`).

---

## 3. Compliance Verdict
**Result:** **PASS (100% Compliant)**  
The platform satisfies all baseline security requirements for Phase D.7.
