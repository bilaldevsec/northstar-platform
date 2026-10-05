output "hub_vnet_id" {
  description = "ID of the Hub Virtual Network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the Hub Virtual Network"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_id" {
  description = "ID of the Spoke Virtual Network"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Name of the Spoke Virtual Network"
  value       = azurerm_virtual_network.spoke.name
}

output "network_resource_group_name" {
  description = "Name of the network resource group"
  value       = azurerm_resource_group.rg.name
}

output "snet_aks_id" {
  description = "Subnet ID for AKS"
  value       = azurerm_subnet.aks.id
}

output "snet_data_id" {
  description = "Subnet ID delegated to PostgreSQL"
  value       = azurerm_subnet.data.id
}

output "snet_pe_id" {
  description = "Subnet ID for Private Endpoints"
  value       = azurerm_subnet.pe.id
}

output "snet_mgmt_id" {
  description = "Subnet ID for management tools"
  value       = azurerm_subnet.mgmt.id
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their IDs"
  value       = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}
