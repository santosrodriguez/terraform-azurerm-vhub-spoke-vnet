terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }

    random = {
      source = "hashicorp/random"
    }

    azurerm = {
      source = "hashicorp/azurerm"

      configuration_aliases = [
        azurerm.CS-PNP-CommonServicesInfra
      ]
    }
  }
}

resource "random_string" "this" {
  length  = 4
  upper   = false
  lower   = false
  special = false
  numeric = true
}

resource "azurecaf_name" "vnet_name" {
  resource_type = "azurerm_virtual_network"

  suffixes = [
    var.solution_name,
    var.location,
    var.environment,
    random_string.this.result
  ]
}

resource "azurerm_virtual_network" "this" {
  name                = azurecaf_name.vnet_name.result
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = each.value.service_endpoints

  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegations

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.subnet_route_table_associations

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = each.value
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_network_security_group_associations

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value
}

resource "azurerm_virtual_hub_connection" "this" {
  count = var.virtual_hub_connection_enabled ? 1 : 0

  provider = azurerm.CS-PNP-CommonServicesInfra

  name                      = azurecaf_name.vnet_name.result
  virtual_hub_id            = var.virtual_hub_id
  remote_virtual_network_id = azurerm_virtual_network.this.id
  internet_security_enabled = var.internet_security_enabled

  lifecycle {
    precondition {
      condition     = try(length(trimspace(var.virtual_hub_id)), 0) > 0
      error_message = "virtual_hub_id is required when virtual_hub_connection_enabled is true."
    }
  }
}

# ------------------------------------------------------------
# Optional Peering: Workload VNet -> Core Services VNet
# ------------------------------------------------------------

resource "azurerm_virtual_network_peering" "workload_to_core_services" {
  count = var.core_services_peering_enabled ? 1 : 0

  name                      = var.core_services_vnet_name
  resource_group_name       = azurerm_virtual_network.this.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = var.core_services_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways

  lifecycle {
    precondition {
      condition = !(
        var.virtual_hub_connection_enabled &&
        var.use_remote_gateways
      )

      error_message = "Invalid routing design: use_remote_gateways cannot be true when this workload VNet is also connected to a vHub."
    }

    precondition {
      condition = (
        var.core_services_vnet_id != null &&
        var.core_services_vnet_name != null
      )

      error_message = "core_services_vnet_id and core_services_vnet_name are required when core_services_peering_enabled is true."
    }
  }

  depends_on = [
    azurerm_virtual_network.this
  ]
}

# ------------------------------------------------------------
# Optional Reverse Peering: Core Services VNet -> Workload VNet
# ------------------------------------------------------------

resource "azurerm_virtual_network_peering" "core_services_to_workload" {
  count = var.core_services_peering_enabled ? 1 : 0

  provider = azurerm.CS-PNP-CommonServicesInfra

  name                      = azurecaf_name.vnet_name.result
  resource_group_name       = var.core_services_resource_group_name
  virtual_network_name      = var.core_services_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.this.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways

  lifecycle {
    precondition {
      condition = (
        var.core_services_resource_group_name != null &&
        var.core_services_vnet_name != null
      )

      error_message = "core_services_resource_group_name and core_services_vnet_name are required when core_services_peering_enabled is true."
    }
  }

  depends_on = [
    azurerm_virtual_network_peering.workload_to_core_services
  ]
}
