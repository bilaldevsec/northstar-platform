resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "psql-nsp-core-dev-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.platform.name
  location               = azurerm_resource_group.platform.location
  version                = "16"
  delegated_subnet_id    = data.azurerm_subnet.data.id
  private_dns_zone_id    = data.azurerm_private_dns_zone.postgres.id
  administrator_login    = "nspadmin"
  administrator_password = random_password.db_password.result
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }
}
