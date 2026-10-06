resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "id-nsp-aks-${var.env}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = data.azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-nsp-core-${var.env}"
  location                  = azurerm_resource_group.platform.location
  resource_group_name       = azurerm_resource_group.platform.name
  dns_prefix                = "aks-nsp-${var.env}"
  sku_tier                  = "Free"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  default_node_pool {
    name            = "system"
    node_count      = 1
    vm_size         = "Standard_B2s_v2"
    vnet_subnet_id  = data.azurerm_subnet.aks.id
    os_disk_size_gb = 30
    os_disk_type    = "Managed"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.240.0.0/16"
    dns_service_ip    = "10.240.0.10"
  }
}
