output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.kv.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = azurerm_key_vault.kv.vault_uri
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_oidc_issuer_url" {
  description = "The OIDC Issuer URL of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "aks_key_vault_secrets_provider_client_id" {
  description = "The Client ID of the AKS Key Vault Secrets Provider."
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "postgres_fqdn" {
  description = "The FQDN of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "postgres_admin_login" {
  description = "The administrator login for the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.db.administrator_login
}
