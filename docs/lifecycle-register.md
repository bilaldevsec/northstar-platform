# Technology Lifecycle and End-of-Life (EOL) Register

| Component | Version In Use | EOL / Retirement Date | Risk / Migration Path | Review Cadence |
| :--- | :--- | :--- | :--- | :--- |
| **Ingress-NGINX Controller** | Deprecated | March 2026 (Official), Nov 2026 (MSFT) | Migrated to Kubernetes Gateway API + Envoy Gateway | Monthly |
| **Kubernetes (AKS)** | v1.30.x / v1.31.x | N-2 Minor Version Policy | Auto-patch channel enabled; minor upgrades scheduled quarterly | Quarterly |
| **PostgreSQL Flexible Server** | v16 | November 2028 | Major version upgrade testing planned for 2027 | Bi-annual |
| **Ubuntu (Worker OS)** | 22.04 / 24.04 LTS | April 2027 / April 2029 | Automatic node OS image upgrades via AKS maintenance window | Monthly |
| **ModSecurity CRS** | CRS v4 / NGINX | Active Community Support | Evaluating cloud-native Envoy WAF filters | Quarterly |
