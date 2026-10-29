variable "location" {
  description = "Azure region where the virtual network will be created."
  type        = string

  validation {
    condition = contains([
      "centralus",
      "eastus",
      "eastus2",
      "northcentralus",
      "southcentralus",
      "westcentralus",
      "westus",
      "westus2",
      "westus3"
    ], lower(var.location))

    error_message = "location must be a valid US Azure region."
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group where the virtual network will be created."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name cannot be empty."
  }
}

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one VNet address space must be provided."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Each address space entry must be a valid CIDR block."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet. Use centralized Azure DNS forwarders when required."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnets to create. The map key is the logical subnet key used by association maps."
  type = map(object({
    name             = string
    address_prefixes = list(string)

    service_endpoints = optional(list(string), [])

    private_endpoint_network_policies = optional(string, null)

    private_link_service_network_policies_enabled = optional(bool, null)

    delegations = optional(map(object({
      name                    = string
      service_delegation_name = string
      actions                 = list(string)
    })), {})
  }))

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      length(subnet.address_prefixes) > 0
    ])

    error_message = "Each subnet must have at least one address prefix."
  }

  validation {
    condition = alltrue(flatten([
      for subnet in var.subnets : [
        for cidr in subnet.address_prefixes :
        can(cidrhost(cidr, 0))
      ]
    ]))

    error_message = "Each subnet address prefix must be a valid CIDR block."
  }
}

variable "subnet_route_table_associations" {
  description = "Map of subnet keys to route table IDs. The key must match a key in var.subnets. Omit subnets that do not need a route table."
  type        = map(string)
  default     = {}
}

variable "subnet_network_security_group_associations" {
  description = "Map of subnet keys to NSG IDs. The key must match a key in var.subnets. Omit subnets that do not need an NSG."
  type        = map(string)
  default     = {}
}

variable "virtual_hub_connection_enabled" {
  description = "Whether to create a vHub connection for this VNet."
  type        = bool
  default     = false
}

variable "virtual_hub_id" {
  description = "ID of the existing Azure Virtual WAN hub. Required when virtual_hub_connection_enabled is true."
  type        = string
  default     = null
}

variable "internet_security_enabled" {
  description = "Whether internet security is enabled for the vHub connection."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the virtual network."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment code used in CAF resource naming."
  type        = string

  validation {
    condition = contains(
      ["prd", "crt", "int", "dev", "spt", "bfx", "sbx"],
      var.environment
    )

    error_message = "Valid environments are prd, crt, int, dev, spt, bfx, sbx."
  }
}

variable "solution_name" {
  description = "Short name for the workload or solution, used in CAF resource naming."
  type        = string

  validation {
    condition     = length(trimspace(var.solution_name)) > 0
    error_message = "solution_name cannot be empty."
  }
}

variable "core_services_peering_enabled" {
  description = "Whether to create peering between this workload VNet and the core services VNet."
  type        = bool
  default     = false
}

variable "core_services_vnet_name" {
  description = "Name of the core services VNet. Required when core_services_peering_enabled is true."
  type        = string
  default     = null
}

variable "core_services_vnet_id" {
  description = "ID of the core services VNet. Required when core_services_peering_enabled is true."
  type        = string
  default     = null
}

variable "core_services_resource_group_name" {
  description = "Resource group name of the core services VNet. Required when core_services_peering_enabled is true."
  type        = string
  default     = null
}

variable "use_remote_gateways" {
  description = "Whether to use remote gateways for the VNet peering."
  type        = bool
  default     = false
}
