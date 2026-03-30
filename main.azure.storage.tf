module "private_dns_zone_storage_account" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  count = var.deployment_mode == "terraform" && local.use_private_networking && !var.azure_alz_platform_landing_zone_mode_enabled ? 1 : 0

  parent_id   = module.resource_group["state"].resource_id
  domain_name = "privatelink.blob.core.windows.net"

  virtual_network_links = {
    vnet_link = {
      vnetlinkname = "storage-account"
      vnetid       = local.effective_vnet_resource_id
    }
  }
}

module "storage_account" {
  source                        = "Azure/avm-res-storage-storageaccount/azurerm"
  version                       = "0.6.8"
  count                         = var.deployment_mode == "terraform" ? 1 : 0
  name                          = local.resource_names.storage_account_name
  location                      = var.location
  resource_group_name           = module.resource_group["state"].name
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  public_network_access_enabled = !local.use_private_networking
  network_rules                 = local.use_private_networking ? {} : null

  containers = { for env_key, env_value in var.environments : env_key => {
    name          = env_key
    public_access = "None"
    role_assignments = {
      user_assignment_managed_identity-plan = {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = module.user_assigned_managed_identity["${env_key}-plan"].principal_id
      }
      user_assignment_managed_identity-apply = {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = module.user_assigned_managed_identity["${env_key}-apply"].principal_id
      }
    }
    }
  }

  private_endpoints_manage_dns_zone_group = !var.azure_alz_platform_landing_zone_mode_enabled
  private_endpoints = local.use_private_networking ? { blob = {
    name                          = local.resource_names.storage_account_private_endpoint_name
    subnet_resource_id            = local.effective_pe_subnet_id
    subresource_name              = "blob"
    private_dns_zone_resource_ids = !var.azure_alz_platform_landing_zone_mode_enabled ? [module.private_dns_zone_storage_account[0].resource_id] : []
    }
  } : {}
}
