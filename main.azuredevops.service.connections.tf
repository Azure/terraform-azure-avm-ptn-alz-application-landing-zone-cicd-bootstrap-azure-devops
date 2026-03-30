resource "azuredevops_serviceendpoint_azurerm" "this" {
  for_each                               = local.environment_split
  project_id                             = local.azure_devops_project_id
  service_endpoint_name                  = each.value.service_connection_name
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = module.user_assigned_managed_identity[each.key].client_id
  }
  azurerm_spn_tenantid      = data.azapi_client_config.current.tenant_id
  azurerm_subscription_id   = local.environments[each.value.environment].subscription_id
  azurerm_subscription_name = data.azapi_resource_action.current_subscription.output.displayName
}

locals {
  environments_with_approvals = { for key, value in var.environments : key => value if value.has_approval }
}

resource "azuredevops_check_approval" "this" {
  for_each             = local.has_approvers ? local.environments_with_approvals : {}
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this["${each.key}-apply"].id
  target_resource_type = "endpoint"

  requester_can_approve = length(var.approvers) == 1
  approvers = [
    local.effective_approvers_origin_id
  ]

  timeout = 43200
}

resource "azuredevops_check_exclusive_lock" "service_connection" {
  for_each             = local.environment_split
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this[each.key].id
  target_resource_type = "endpoint"
  timeout              = 43200
}

resource "azuredevops_check_required_template" "this" {
  for_each             = local.environment_split
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this[each.key].id
  target_resource_type = "endpoint"

  dynamic "required_template" {
    for_each = { for template in each.value.required_templates : template => template }
    content {
      repository_type = "azuregit"
      repository_name = "${local.azure_devops_project_name}/${local.effective_template_repo_name}"
      repository_ref  = local.default_branch
      template_path   = required_template.value
    }
  }
}
