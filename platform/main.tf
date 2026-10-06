resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
  lower   = true
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-nsp-platform-${var.env}"
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                          = "kv-nsp-plat-${var.env}-${random_string.suffix.result}"
  location                      = azurerm_resource_group.platform.location
  resource_group_name           = azurerm_resource_group.platform.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  purge_protection_enabled      = true
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${azurerm_key_vault.kv.name}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  subnet_id           = data.azurerm_subnet.pe.id

  private_service_connection {
    name                           = "psc-${azurerm_key_vault.kv.name}"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${azurerm_key_vault.kv.name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.kv.id]
  }
}
