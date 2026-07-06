locals {
  environments_byo_scope = { for env_key, env_value in local.environments : env_key => env_value if !env_value.create_resource_group }
  environments_create_rg = { for env_key, env_value in local.environments : env_key => env_value if env_value.create_resource_group }
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
  role_assignments = { for ra in flatten([for identity_key in ["read", "write"] : [
    for ra_key, ra_value in each.value.identities[identity_key].role_assignments : {
      key          = "${identity_key}-${ra_key}"
      role         = ra_value.role_definition_id_or_name
      principal_id = module.user_assigned_managed_identity["${each.key}-${identity_key}"].principal_id
    }
    ] if each.value.identities[identity_key].enabled]) : ra.key => {
    role_definition_id_or_name = ra.role
    principal_id               = ra.principal_id
  } }
}

locals {
  byo_scope_role_assignments = { for ra in flatten([for env_key, env_value in local.environments_byo_scope : [
    for identity_key in ["read", "write"] : [
      for ra_key, ra_value in env_value.identities[identity_key].role_assignments : {
        key                        = "${env_key}-${identity_key}-${ra_key}"
        scope                      = env_value.resource_id
        subscription_id            = env_value.subscription_id
        role_definition_id_or_name = ra_value.role_definition_id_or_name
        principal_id               = module.user_assigned_managed_identity["${env_key}-${identity_key}"].principal_id
      }
    ] if env_value.identities[identity_key].enabled
  ]]) : ra.key => ra }
}

resource "azapi_resource" "role_assignment" {
  for_each = local.byo_scope_role_assignments

  name      = uuidv5("url", "${each.value.scope}-${each.value.principal_id}-${each.value.role_definition_id_or_name}")
  parent_id = each.value.scope
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = each.value.principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = can(regex("^/", each.value.role_definition_id_or_name)) ? each.value.role_definition_id_or_name : "/subscriptions/${each.value.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${module.role_definitions.role_definition_rolename_to_name[each.value.role_definition_id_or_name]}"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
