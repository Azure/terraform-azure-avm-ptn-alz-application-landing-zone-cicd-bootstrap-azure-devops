locals {
  resource_groups = merge(
    var.deployment_mode == "terraform" ? {
      state = {
        name = local.resource_names.resource_group_state_name
      }
    } : {},
    {
      identity = {
        name = local.resource_names.resource_group_identity_name
      }
    },
    local.create_vnet_infrastructure ? {
      agents = {
        name = local.resource_names.resource_group_agents_name
      }
    } : {},
  )

  environments_create_rg = { for env_key, env_value in local.environments : env_key => env_value if env_value.create_resource_group }
  environments_byo_scope = { for env_key, env_value in local.environments : env_key => env_value if !env_value.create_resource_group }
}

module "resource_group" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.2.2"
  for_each = local.resource_groups
  location = var.location
  name     = each.value.name
}

module "resource_group_environments" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.2.2"
  for_each = local.environments_create_rg
  location = var.location
  name     = each.value.resource_group_name
  role_assignments = {
    reader = {
      role_definition_id_or_name = "Reader"
      principal_id               = module.user_assigned_managed_identity["${each.key}-plan"].principal_id
    }
    contributor = {
      role_definition_id_or_name = "Contributor"
      principal_id               = module.user_assigned_managed_identity["${each.key}-apply"].principal_id
    }
  }
}

resource "azurerm_role_assignment" "environment_plan" {
  for_each             = local.environments_byo_scope
  scope                = each.value.resource_id
  role_definition_name = "Reader"
  principal_id         = module.user_assigned_managed_identity["${each.key}-plan"].principal_id
}

resource "azurerm_role_assignment" "environment_apply" {
  for_each             = local.environments_byo_scope
  scope                = each.value.resource_id
  role_definition_name = "Contributor"
  principal_id         = module.user_assigned_managed_identity["${each.key}-apply"].principal_id
}
