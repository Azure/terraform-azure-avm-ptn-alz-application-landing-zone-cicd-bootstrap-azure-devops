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
    plan = {
      role_definition_id_or_name = each.value.plan_role_definition_id_or_name
      principal_id               = module.user_assigned_managed_identity["${each.key}-plan"].principal_id
    }
    apply = {
      role_definition_id_or_name = each.value.apply_role_definition_id_or_name
      principal_id               = module.user_assigned_managed_identity["${each.key}-apply"].principal_id
    }
  }
}

locals {
  byo_scope_role_assignments = { for ra in flatten([for env_key, env_value in local.environments_byo_scope : [
    {
      key                        = "${env_key}-plan"
      scope                      = env_value.resource_id
      role_definition_id_or_name = env_value.plan_role_definition_id_or_name
      principal_id               = module.user_assigned_managed_identity["${env_key}-plan"].principal_id
    },
    {
      key                        = "${env_key}-apply"
      scope                      = env_value.resource_id
      role_definition_id_or_name = env_value.apply_role_definition_id_or_name
      principal_id               = module.user_assigned_managed_identity["${env_key}-apply"].principal_id
    },
  ]]) : ra.key => ra }
}

resource "azapi_resource" "role_assignment" {
  for_each  = local.byo_scope_role_assignments
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${each.value.scope}-${each.value.principal_id}-${each.value.role_definition_id_or_name}")
  parent_id = each.value.scope
  body = {
    properties = {
      principalId      = each.value.principal_id
      roleDefinitionId = can(regex("^/", each.value.role_definition_id_or_name)) ? each.value.role_definition_id_or_name : "${each.value.scope}/providers/Microsoft.Authorization/roleDefinitions/${each.value.role_definition_id_or_name}"
    }
  }
}
