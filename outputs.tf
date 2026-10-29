output "virtual_network_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "virtual_network_resource_group_name" {
  description = "Resource group name of the virtual network."
  value       = azurerm_virtual_network.this.resource_group_name
}

output "virtual_network_location" {
  description = "Azure region of the virtual network."
  value       = azurerm_virtual_network.this.location
}

output "virtual_network_address_space" {
  description = "Address space of the virtual network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet keys to subnet IDs."
  value = {
    for subnet_key, subnet in azurerm_subnet.this :
    subnet_key => subnet.id
  }
}

output "subnet_names" {
  description = "Map of subnet keys to subnet names."
  value = {
    for subnet_key, subnet in azurerm_subnet.this :
    subnet_key => subnet.name
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet keys to subnet address prefixes."
  value = {
    for subnet_key, subnet in azurerm_subnet.this :
    subnet_key => subnet.address_prefixes
  }
}

output "subnet_route_table_association_ids" {
  description = "Map of subnet keys to subnet route table association IDs."
  value = {
    for subnet_key, association in azurerm_subnet_route_table_association.this :
    subnet_key => association.id
  }
}

output "subnet_network_security_group_association_ids" {
  description = "Map of subnet keys to subnet NSG association IDs."
  value = {
    for subnet_key, association in azurerm_subnet_network_security_group_association.this :
    subnet_key => association.id
  }
}

output "virtual_hub_connection_id" {
  description = "ID of the vHub connection. Returns null when virtual_hub_connection_enabled is false."
  value       = try(azurerm_virtual_hub_connection.this[0].id, null)
}

output "virtual_hub_connection_name" {
  description = "Name of the vHub connection. Returns null when virtual_hub_connection_enabled is false."
  value       = try(azurerm_virtual_hub_connection.this[0].name, null)
}
