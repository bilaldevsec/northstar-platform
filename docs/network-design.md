# NorthStar Network Architecture Design Document

**Target Architecture:** Hub-and-Spoke Enterprise Topology  
**Region:** Southeast Asia (`southeastasia`)  
**Environment:** NorthStar Platform (Dev / Prod Baseline)  
**Classification:** Internal Technical Architecture  

---

## 1. Network Topology Overview

The NorthStar platform implements an enterprise hub-and-spoke virtual network architecture designed for strict zero-trust network segmentation, non-transitive perimeter isolation, and centralized egress inspection.

```
+---------------------------------------------------------------------------------------+
|                                HUB VNET (10.0.0.0/22)                                 |
|                                                                                       |
|  +--------------------------+  +--------------------------+  +---------------------+  |
|  |   AzureFirewallSubnet    |  |    AzureBastionSubnet    |  |      snet-mgmt      |  |
|  |      10.0.0.0/26         |  |       10.0.0.64/26       |  |     10.0.1.0/24     |  |
|  +--------------------------+  +--------------------------+  +---------------------+  |
+---------------------------------------------------------------------------------------+
                                           |
                                  VNet Peering (Non-Transitive)
                                  AllowForwardedTraffic: True
                                  AllowGatewayTransit: False
                                           |
+---------------------------------------------------------------------------------------+
|                               SPOKE VNET (10.1.0.0/16)                                |
|                                                                                       |
|  +---------------------+  +---------------------+  +-------------------------------+  |
|  |      snet-aks       |  |      snet-data      |  |            snet-pe            |  |
|  |     10.1.0.0/24     |  |     10.1.1.0/24     |  |          10.1.2.0/24          |  |
|  |  (AKS Node Pools)   |  | (PostgreSQL Deleg)  |  |      (Private Endpoints)      |  |
|  +---------------------+  +---------------------+  +-------------------------------+  |
|                                                                                       |
|  +---------------------+                                                              |
|  |      snet-test      |                                                              |
|  |     10.1.4.0/24     |                                                              |
|  |   (Ephemeral VMs)   |                                                              |
|  +---------------------+                                                              |
+---------------------------------------------------------------------------------------+
```

---

## 2. IP Addressing Architecture

### 2.1 Hub Virtual Network (`10.0.0.0/22`)
The Hub VNet acts as the central connectivity point for administrative access, telemetry, and perimeter security.

| Subnet Name | Address Prefix | Purpose / Attached Workloads | NSG Associated |
| :--- | :--- | :--- | :--- |
| **`AzureFirewallSubnet`** | `10.0.0.0/26` | Reserved for Azure Firewall central inspection | *None (Managed)* |
| **`AzureBastionSubnet`** | `10.0.0.64/26` | Secure RDP/SSH jump gateway without public IPs | *Managed Bastion NSG* |
| **`snet-mgmt`** | `10.0.1.0/24` | Management jump boxes, administrative toolrunners | `nsg-nsp-mgmt-dev` |

### 2.2 Spoke Virtual Network (`10.1.0.0/16`)
The Spoke VNet isolates application workloads, persistent data stores, and private integration endpoints.

| Subnet Name | Address Prefix | Purpose / Attached Workloads | NSG Associated |
| :--- | :--- | :--- | :--- |
| **`snet-aks`** | `10.1.0.0/24` | Azure Kubernetes Service (AKS) node pools & pods (Azure CNI Overlay) | Subnet NSG / Pod Network Policies |
| **`snet-data`** | `10.1.1.0/24` | Delegated to `Microsoft.DBforPostgreSQL/flexibleServers` | `nsg-nsp-data-dev` |
| **`snet-pe`** | `10.1.2.0/24` | Azure Private Endpoints (Key Vault, Storage Accounts, ACR) | `nsg-nsp-pe-dev` |
| **`snet-test`** | `10.1.4.0/24` | Ephemeral test VMs and network connectivity verification | `nsg-nsp-test-dev` |

---

## 3. Routing & Security Boundaries

### 3.1 Non-Transitive VNet Peering
- Direct bidirectional VNet peering connects Hub (`vnet-nsp-hub-dev`) and Spoke (`vnet-nsp-spoke-dev`).
- **Non-Transitivity:** Spoke networks cannot route traffic to other spokes or on-premises networks across the peering without explicit User Defined Routes (UDR) pointing to a Network Virtual Appliance (NVA).
- Gateway transit is disabled (`allow_gateway_transit = false`).

### 3.2 Network Security Groups (NSGs) & Default-Deny Model
- The default Azure platform rule `AllowVnetInBound` (Priority 65000) permits all traffic within virtual networks by default.
- NorthStar enforces an explicit zero-trust model:
  1. High-priority explicit rules permit only required inter-subnet communication (e.g., Hub Management to Spoke Test on port 22).
  2. Overriding deny rules (e.g., `DenyAllInbound` at priority 4096 or custom deny rules) supersede default Azure rules.
  3. Database subnet `snet-data` denies direct ingress from management subnets and only permits authenticated microservice access from AKS worker pods.

---

## 4. Verification Checkpoints
- **Lab N2:** Hub management VM can SSH into spoke test VM (`10.0.1.x:50000 -> 10.1.4.x:22`).
- **Lab N3 & N5:** Hub management VM is strictly blocked by NSG rules from directly reaching the database tier (`10.1.1.x:5432`).
- **Lab N8:** VNet flow logs enable continuous traffic analysis and NSG flow inspection.
