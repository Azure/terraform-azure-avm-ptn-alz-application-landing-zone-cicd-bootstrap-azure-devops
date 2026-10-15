module "ip_addresses" {
  source  = "Azure/avm-utl-network-ip-addresses/azurerm"
  version = "0.1.1"
  count   = local.create_vnet_infrastructure ? 1 : 0

  address_prefixes = var.azure_subnets_and_sizes
  address_space    = var.azure_address_space
}

locals {
  subnet_delegation_type = var.agent_compute_type == "azure_container_app" ? "Microsoft.App/environments" : "Microsoft.ContainerInstance/containerGroups"
  subnet_delegations = { for key, value in var.azure_subnets_and_sizes : key => key == "agents" ? [
    {
      name = local.subnet_delegation_type
      service_delegation = {
        name = local.subnet_delegation_type
      }
    }
  ] : [] }
  subnets = local.create_vnet_infrastructure ? module.ip_addresses[0].address_prefixes : {}
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.20.0"
  count   = local.create_vnet_infrastructure ? 1 : 0

  location      = var.location
  parent_id     = module.resource_group["agents"].resource_id
  address_space = [var.azure_address_space]
  name          = local.resource_names.virtual_network_name
  subnets = { for subnet_key, subnet_address_space in local.subnets : subnet_key => {
    name             = subnet_key
    address_prefixes = [subnet_address_space]
    delegations      = local.subnet_delegations[subnet_key]
  } }
}
