resource "azuredevops_variable_group" "this" {
  for_each     = local.create_main_repository && var.deployment_mode == "terraform" ? var.environments : {}
  project_id   = local.azure_devops_project_id
  name         = each.key
  description  = "Variable Group for ${each.value.display_name}"
  allow_access = true

  variable {
    name = "ADDITIONAL_ENVIRONMENT_VARIABLES"
    value = jsonencode(merge(
      local.environments[each.key].create_resource_group ? {
        TF_VAR_resource_group_name = module.resource_group_environments[each.key].name
      } : {},
      local.environments[each.key].scope == "subscription" || local.environments[each.key].scope == "management_group" ? {
        TF_VAR_subscription_id = local.environments[each.key].subscription_id
      } : {},
    ))
  }

  variable {
    name  = "VAR_FILE_PATH"
    value = "./config/${each.key}.tfvars"
  }

  variable {
    name  = "BACKEND_AZURE_STORAGE_ACCOUNT_NAME"
    value = module.storage_account[0].name
  }

  variable {
    name  = "BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME"
    value = each.key
  }
}

resource "azuredevops_variable_group" "bicep" {
  for_each     = local.create_main_repository && var.deployment_mode == "bicep" ? var.environments : {}
  project_id   = local.azure_devops_project_id
  name         = each.key
  description  = "Variable Group for ${each.value.display_name}"
  allow_access = true

  variable {
    name  = "BICEP_DEPLOYMENTS"
    value = var.bicep_deployments != null ? jsonencode(var.bicep_deployments) : "[]"
  }
}
