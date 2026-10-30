module "private_dns_zone_storage_account" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"
  count   = var.deployment_mode == "terraform" && local.use_private_networking && !var.azure_alz_platform_landing_zone_mode_enabled ? 1 : 0

  domain_name = "privatelink.blob.core.windows.net"
  parent_id   = module.resource_group["state"].resource_id
  virtual_network_links = {
    vnet_link = {
      vnetlinkname = "storage-account"
      vnetid       = local.effective_vnet_resource_id
    }
  }
}

resource "terraform_data" "plan_storage_container_validation" {
  count = var.deployment_mode == "terraform" && var.use_storage_account_for_plan ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(local.plan_storage_container_backend_collisions) == 0
      error_message = "Computed plan storage container name(s) collide with an existing backend state container: ${join(", ", local.plan_storage_container_backend_collisions)}."
    }
    precondition {
      condition     = length(local.plan_storage_container_duplicate_names) == 0
      error_message = "Computed plan storage container name(s) collide across environments: ${join(", ", local.plan_storage_container_duplicate_names)}."
    }
  }
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"
  count   = var.deployment_mode == "terraform" ? 1 : 0

  location                 = var.location
  name                     = local.resource_names.storage_account_name
  resource_group_name      = module.resource_group["state"].name
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  containers = merge(
    { for env_key, env_value in local.environments : env_key => {
      name          = env_key
      public_access = "None"
      role_assignments = { for identity_key, identity_value in env_value.identities : "uami-${identity_key}" => {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = module.user_assigned_managed_identity["${env_key}-${identity_key}"].principal_id
      } if identity_value.enabled }
      }
    },
    { for env_key, container_name in local.plan_storage_container_names : container_name => {
      name          = container_name
      public_access = "None"
      role_assignments = { for identity_key, identity_value in local.environments[env_key].identities : "uami-${identity_key}" => {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = module.user_assigned_managed_identity["${env_key}-${identity_key}"].principal_id
      } if identity_value.enabled }
      }
    }
  )
  network_rules = local.use_private_networking ? {} : null
  private_endpoints = local.use_private_networking ? { blob = {
    name                          = local.resource_names.storage_account_private_endpoint_name
    subnet_resource_id            = local.effective_pe_subnet_id
    subresource_name              = "blob"
    private_dns_zone_resource_ids = !var.azure_alz_platform_landing_zone_mode_enabled ? [module.private_dns_zone_storage_account[0].resource_id] : []
    }
  } : {}
  private_endpoints_manage_dns_zone_group = !var.azure_alz_platform_landing_zone_mode_enabled
  public_network_access_enabled           = !local.use_private_networking
  storage_management_policy_rule = { for env_key, container_name in local.plan_storage_container_names : env_key => {
    name    = "plan${replace(env_key, "/[^a-zA-Z0-9]/", "")}"
    enabled = true
    filters = {
      blob_types   = ["blockBlob"]
      prefix_match = ["${container_name}/runs/"]
    }
    actions = {
      base_blob = {
        delete_after_days_since_modification_greater_than = var.plan_storage_retention_days
      }
      snapshot = {
        delete_after_days_since_creation_greater_than = var.plan_storage_retention_days
      }
      version = {
        delete_after_days_since_creation = var.plan_storage_retention_days
      }
    }
  } }
}
