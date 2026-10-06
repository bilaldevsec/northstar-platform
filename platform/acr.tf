resource "azurerm_container_registry" "acr" {
  name                = "crnspcore${var.env}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "Basic"
  admin_enabled       = false
}
