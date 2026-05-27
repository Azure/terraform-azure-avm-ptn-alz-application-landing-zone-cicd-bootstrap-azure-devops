resource "azuredevops_environment" "this" {
  for_each   = local.create_main_repository ? var.environments : {}
  name       = each.key
  project_id = local.azure_devops_project_id
}

resource "azuredevops_check_exclusive_lock" "environment" {
  for_each             = local.create_main_repository ? var.environments : {}
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_environment.this[each.key].id
  target_resource_type = "environment"
  timeout              = 43200
}
