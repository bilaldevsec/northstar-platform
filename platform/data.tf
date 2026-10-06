data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "network" {
  name = "rg-nsp-network-dev"
}

data "azurerm_virtual_network" "spoke" {
  name                = "vnet-nsp-spoke-dev"
  resource_group_name = data.azurerm_resource_group.network.name
}

data "azurerm_subnet" "pe" {
  name                 = "snet-pe"
  virtual_network_name = data.azurerm_virtual_network.spoke.name
  resource_group_name  = data.azurerm_resource_group.network.name
}

data "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.network.name
}
