resource "azuredevops_variable_group" "this" {
  for_each = local.create_main_repository && var.deployment_mode == "terraform" ? var.environments : {}

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
  variable {
    name  = "USE_STORAGE_ACCOUNT_FOR_PLAN"
    value = var.use_storage_account_for_plan ? "true" : "false"
  }
  variable {
    name  = "SHOW_PLAN_IN_PIPELINE_LOGS"
    value = var.show_plan_in_pipeline_logs ? "true" : "false"
  }
  dynamic "variable" {
    for_each = var.use_storage_account_for_plan && contains(keys(local.plan_storage_container_names), each.key) ? [1] : []

    content {
      name  = "PLAN_STORAGE_CONTAINER_NAME"
      value = local.plan_storage_container_names[each.key]
    }
  }
}

resource "azuredevops_variable_group" "bicep" {
  for_each = local.create_main_repository && var.deployment_mode == "bicep" ? var.environments : {}

  project_id   = local.azure_devops_project_id
  name         = each.key
  description  = "Variable Group for ${each.value.display_name}"
  allow_access = true

  variable {
    name  = "BICEP_DEPLOYMENTS"
    value = var.bicep_deployments != null ? jsonencode(var.bicep_deployments) : "[]"
  }
}
