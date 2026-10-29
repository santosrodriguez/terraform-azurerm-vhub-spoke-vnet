# Azure Virtual Network with Virtual Hub Connection

## Overview

This Terraform module creates an Azure virtual network, optional subnets, optional subnet network security group associations, optional subnet route table associations, and an optional virtual hub connection to an existing Azure Virtual WAN hub.

The module is intended for spoke virtual networks that connect to an existing vHub. It supports enabling internet security on the vHub connection, which allows the connected VNet to use the vHub security and routing configuration already defined in the connectivity environment.

## What This Module Deploys

This module deploys the following Azure resources and configurations:

- `azurerm_virtual_network`
- `azurerm_subnet` resources from the `subnets` map
- `azurerm_subnet_network_security_group_association` when a subnet provides `network_security_group_id`
- `azurerm_subnet_route_table_association` when a subnet provides `route_table_id`
- `azurerm_virtual_hub_connection` when `vhub_connection_enabled` is `true`
- Subnet delegations using a dynamic `delegation` block when subnet delegations are provided
- Validation using `terraform_data.validate_vhub_connection` to require vHub connection values when vHub connection creation is enabled

## Requirements

| Requirement | Details |
|---|---|
| Terraform version | Not explicitly defined. The module uses `terraform_data`, so the Terraform version must support the `terraform_data` resource. |
| Required providers | `azurerm` |
| Required provider versions | Not explicitly defined. |
| Provider aliases | The module uses the default `azurerm` provider and the aliased provider `azurerm.connectivity` for the `azurerm_virtual_hub_connection` resource. |
| Azure prerequisites | An existing resource group is required. An existing Azure Virtual WAN hub is required when `vhub_connection_enabled` is `true`. |
| Required permissions or role assumptions | Not explicitly defined. The caller must have permissions to create and manage virtual networks, subnets, subnet associations, and virtual hub connections in the target subscriptions or resource groups. |

## Required Parameters

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Name of the virtual network. |
| `location` | `string` | Azure region where the virtual network will be created. |
| `resource_group_name` | `string` | Name of the existing resource group where the virtual network will be created. |
| `address_space` | `list(string)` | Address space for the virtual network. |

## Optional Parameters

| Name | Type | Default | Description |
|---|---|---|---|
| `dns_servers` | `list(string)` | `[]` | Custom DNS servers for the VNet. Use centralized Azure DNS forwarders when required. |
| `subnets` | `map(object)` | `{}` | Map of subnets to create. Each subnet can include service endpoints, private endpoint network policies, private link service network policy settings, NSG association, route table association, and delegations. |
| `vhub_connection_enabled` | `bool` | `true` | Whether to create a vHub connection for this VNet. |
| `vhub_connection_name` | `string` | `null` | Name of the vHub connection. Required when `vhub_connection_enabled` is `true`. |
| `virtual_hub_id` | `string` | `null` | ID of the existing Azure Virtual WAN hub. Required when `vhub_connection_enabled` is `true`. |
| `internet_security_enabled` | `bool` | `true` | Whether internet security is enabled for the vHub connection. |
| `tags` | `map(string)` | `{}` | Tags to apply to the virtual network. |

## Default Parameter Values

| Parameter | Default Value | Purpose |
|---|---|---|
| `dns_servers` | `[]` | Uses Azure-provided DNS unless custom DNS servers are provided. |
| `subnets` | `{}` | Creates no subnets unless subnet definitions are provided. |
| `subnets[*].service_endpoints` | `[]` | Creates subnets without service endpoints unless provided. |
| `subnets[*].private_endpoint_network_policies` | `"Disabled"` | Disables private endpoint network policies by default. |
| `subnets[*].private_link_service_network_policies_enabled` | `true` | Enables private link service network policies by default. |
| `subnets[*].delegations` | `{}` | Creates no subnet delegations unless provided. |
| `vhub_connection_enabled` | `true` | Creates a vHub connection by default. |
| `vhub_connection_name` | `null` | Requires the caller to provide a vHub connection name when vHub connection creation is enabled. |
| `virtual_hub_id` | `null` | Requires the caller to provide an existing vHub ID when vHub connection creation is enabled. |
| `internet_security_enabled` | `true` | Enables internet security on the vHub connection by default. |
| `tags` | `{}` | Applies no tags unless provided. |

## Minimum Required Example

Because `vhub_connection_enabled` defaults to `true`, `vhub_connection_name` and `virtual_hub_id` must be provided for the default hub-connected behavior.

```hcl
module "vnet" {
  source        = "caresource.pe.jfrog.io/shared-tfmodules-internal__network/vhub-spoke-vnet/azurerm"
  version       = "0.0.5"

  providers =   {
    azurerm = azurerm
    azurerm.CS-PNP-CommonServicesInfra = azurerm.CS-PNP-CommonServicesInfra
  } 

  name                = "vnet-dev-eastus-app-001"
  location            = "eastus"
  resource_group_name = "rg-dev-eastus-network-001"
  address_space       = ["10.40.0.0/16"]

  vhub_connection_name = "conn-vnet-dev-eastus-app-001"
  virtual_hub_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod-eastus-connectivity-001/providers/Microsoft.Network/virtualHubs/vhub-prod-eastus-001"
}
```

## Full Example

```hcl
module "vnet" {
  source = "./modules/vnet"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  name                = "vnet-prod-eastus-app-001"
  location            = "eastus"
  resource_group_name = "rg-prod-eastus-network-001"
  address_space       = ["10.50.0.0/16"]

  dns_servers = [
    "10.10.0.4",
    "10.10.0.5"
  ]

  subnets = {
    app = {
      name             = "snet-prod-eastus-app-001"
      address_prefixes = ["10.50.1.0/24"]

      service_endpoints = [
        "Microsoft.Storage"
      ]

      private_endpoint_network_policies = "Disabled"

      network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod-eastus-network-001/providers/Microsoft.Network/networkSecurityGroups/nsg-prod-eastus-app-001"
      route_table_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod-eastus-network-001/providers/Microsoft.Network/routeTables/rt-prod-eastus-app-001"
    }

    private_endpoints = {
      name             = "snet-prod-eastus-pe-001"
      address_prefixes = ["10.50.2.0/24"]

      private_endpoint_network_policies = "Disabled"
    }

    delegated = {
      name             = "snet-prod-eastus-delegated-001"
      address_prefixes = ["10.50.3.0/24"]

      delegations = {
        app_service = {
          name                    = "delegation-app-service"
          service_delegation_name = "Microsoft.Web/serverFarms"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/action"
          ]
        }
      }
    }
  }

  vhub_connection_enabled = true
  vhub_connection_name    = "conn-vnet-prod-eastus-app-001"
  virtual_hub_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod-eastus-connectivity-001/providers/Microsoft.Network/virtualHubs/vhub-prod-eastus-001"

  internet_security_enabled = true

  tags = {
    environment = "prod"
    workload    = "app"
    managed_by  = "terraform"
  }
}
```

Example with vHub connection disabled:

```hcl
module "vnet_no_vhub_connection" {
  source        = "caresource.pe.jfrog.io/shared-tfmodules-internal__network/vhub-spoke-vnet/azurerm"
  version       = "0.0.5"

  providers =   {
    azurerm = azurerm
    azurerm.CS-PNP-CommonServicesInfra = azurerm.CS-PNP-CommonServicesInfra
  } 


  name                = "vnet-dev-eastus-standalone-001"
  location            = "eastus"
  resource_group_name = "rg-dev-eastus-network-001"
  address_space       = ["10.60.0.0/16"]

  vhub_connection_enabled = false

  tags = {
    environment = "dev"
    workload    = "standalone"
    managed_by  = "terraform"
  }
}
```

## Outputs

| Name | Description |
|---|---|
| `virtual_network_id` | ID of the virtual network. |
| `virtual_network_name` | Name of the virtual network. |
| `virtual_network_resource_group_name` | Resource group name of the virtual network. |
| `virtual_network_location` | Azure region of the virtual network. |
| `virtual_network_address_space` | Address space of the virtual network. |
| `subnet_ids` | Map of subnet keys to subnet IDs. |
| `subnet_names` | Map of subnet keys to subnet names. |
| `subnet_address_prefixes` | Map of subnet keys to subnet address prefixes. |
| `virtual_hub_connection_id` | ID of the vHub connection. Returns `null` when `vhub_connection_enabled` is `false`. |
| `virtual_hub_connection_name` | Name of the vHub connection. Returns `null` when `vhub_connection_enabled` is `false`. |

## Best Practices

- Use a consistent VNet naming standard that includes workload, environment, region, and instance number.
- Use a consistent subnet naming standard that clearly identifies the subnet purpose.
- Apply tags through `tags` for environment, workload, owner, cost center, and Terraform management.
- Keep address spaces non-overlapping across all VNets connected to the same vHub.
- Use separate remote state files or workspaces for different environments such as `dev`, `test`, and `prod`.
- Manage the connectivity provider configuration separately when the vHub exists in a centralized connectivity subscription.
- Use `azurerm.connectivity` for the vHub connection when the vHub is managed in a different subscription than the spoke VNet.
- Use network security groups for subnet-level traffic control where required.
- Use route tables only where they are compatible with the organization’s Virtual WAN and routing intent design.
- Keep private endpoint subnets separate from application subnets when possible.
- Confirm that the existing vHub routing intent is configured for private and internet traffic before relying on centralized routing behavior.
- Use Azure Policy and governance controls to enforce naming, tagging, allowed regions, and network security standards.

## Notes

- The virtual network name is set directly from `var.name`.
- The virtual network is created in `var.resource_group_name` and `var.location`.
- The module does not create the resource group.
- The module does not create the virtual hub.
- The module does not configure vHub routing intent.
- The module creates a vHub connection by default because `vhub_connection_enabled` defaults to `true`.
- When `vhub_connection_enabled` is `true`, both `vhub_connection_name` and `virtual_hub_id` are required.
- When `vhub_connection_enabled` is `false`, `vhub_connection_name` and `virtual_hub_id` are not required.
- The `terraform_data.validate_vhub_connection` resource validates that `vhub_connection_name` and `virtual_hub_id` are not `null` or empty when vHub connection creation is enabled.
- The vHub connection is created with `provider = azurerm.connectivity`.
- The vHub connection uses `azurerm_virtual_network.this.id` as `remote_virtual_network_id`.
- The vHub connection sets `internet_security_enabled` from `var.internet_security_enabled`.
- When the existing vHub uses routing intent for private and internet traffic, routing behavior is controlled by the vHub routing intent configuration, not by this module.
- Subnets are created using `for_each = var.subnets`.
- Subnet keys from `var.subnets` are used as map keys for subnet outputs.
- Each subnet name is set from `each.value.name`.
- Each subnet address prefix list is set from `each.value.address_prefixes`.
- Subnet network security group associations are created only for subnets where `network_security_group_id` is not `null`.
- Subnet route table associations are created only for subnets where `route_table_id` is not `null`.
- Subnet delegations are created using a dynamic `delegation` block from each subnet’s `delegations` map.
- The `location` variable only allows the following lowercase or case-insensitive US Azure regions: `centralus`, `eastus`, `eastus2`, `northcentralus`, `southcentralus`, `westcentralus`, `westus`, `westus2`, and `westus3`.
- The `private_endpoint_network_policies` value must be one of `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled`, or `RouteTableEnabled`.
- If `vhub_connection_enabled` is `false`, the vHub connection outputs return `null`.
