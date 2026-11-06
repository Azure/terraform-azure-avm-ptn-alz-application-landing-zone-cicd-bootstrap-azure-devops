module "ip_addresses" {
  source  = "Azure/avm-utl-network-ip-addresses/azurerm"
  version = "0.1.1"
  count   = local.create_vnet_infrastructure ? 1 : 0

  address_prefixes = var.azure_subnets_and_sizes
  address_space    = var.azure_address_space
}

locals {
  subnet_delegation_type = var.agent_compute_type == "azure_container_app" ? "Microsoft.App/environments" : var.agent_compute_type == "azure_container_instance" ? "Microsoft.ContainerInstance/containerGroups" : "Microsoft.DevOpsInfrastructure/pools"
  subnet_delegations = { for key, value in var.azure_subnets_and_sizes : key => key == "agents" ? [
    {
      name = local.subnet_delegation_type
      service_delegation = {
        name = local.subnet_delegation_type
      }
    }
  ] : [] }
  subnets = local.create_vnet_infrastructure ? module.ip_addresses[0].address_prefixes : {}
  devops_infrastructure_roles = local.create_agent_managed_pool_infrastructure && local.create_vnet_infrastructure ? [
    "Reader",
    "Network Contributor"
  ] : []
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"
  count   = local.create_vnet_infrastructure ? 1 : 0

  location      = var.location
  parent_id     = module.resource_group["agents"].resource_id
  address_space = [var.azure_address_space]
  name          = local.resource_names.virtual_network_name
  role_assignments = {
    for role in local.devops_infrastructure_roles : role => {
      role_definition_id_or_name = role
      principal_id               = data.azuread_service_principal.devops_infra.object_id
    }
  }
  subnets = { for subnet_key, subnet_address_space in local.subnets : subnet_key => {
    name             = subnet_key
    address_prefixes = [subnet_address_space]
    delegations      = local.subnet_delegations[subnet_key]

    nat_gateway = length(module.nat_gateway) > 0 ? {
      id = module.nat_gateway[0].resource_id
    } : null
  } }
}

module "nat_gateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"
  count   = local.create_agent_managed_pool_infrastructure && local.create_vnet_infrastructure ? 1 : 0

  location  = var.location
  name      = local.resource_names.nat_gateway_name
  parent_id = module.resource_group["agents"].resource_id
  public_ip_configuration = {
    devops_managed_pool_ip = {
      allocation_method       = "Static"
      idle_timeout_in_minutes = 15
    }
  }
  public_ips = {
    devops_managed_pool_ip = {
      name = local.resource_names.nat_gateway_public_ip_name
    }
  }
}
