data "azuredevops_project" "this" {
  count = var.azuredevops_create_project ? 0 : 1
  name  = var.azuredevops_project_name
}

resource "azuredevops_project" "this" {
  count = var.azuredevops_create_project ? 1 : 0
  name  = local.resource_names.project_name
}

locals {
  azure_devops_project_id   = var.azuredevops_create_project ? azuredevops_project.this[0].id : data.azuredevops_project.this[0].id
  azure_devops_project_name = var.azuredevops_create_project ? azuredevops_project.this[0].name : data.azuredevops_project.this[0].name
}
