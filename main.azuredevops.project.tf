data "azuredevops_project" "this" {
  count = var.create_project ? 0 : 1
  name  = var.project_name
}

resource "azuredevops_project" "this" {
  count = var.create_project ? 1 : 0
  name  = local.resource_names.project_name
}

locals {
  azure_devops_project_name = var.create_project ? azuredevops_project.this[0].name : data.azuredevops_project.this[0].name
  azure_devops_project_id   = var.create_project ? azuredevops_project.this[0].id : data.azuredevops_project.this[0].id
}
