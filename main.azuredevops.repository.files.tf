locals {
  effective_pipeline_folder = var.azuredevops_pipeline_folder_path != null ? var.azuredevops_pipeline_folder_path : (
    contains(["terraform", "bicep"], var.deployment_mode) ? "${path.module}/pipelines/${var.deployment_mode}" : null
  )
  environment_replacements = { for environment_key, environment_value in var.environments : "${format("%03s", environment_value.display_order)}-${environment_key}" => {
    name                          = lower(replace(environment_key, "-", ""))
    display_name                  = environment_value.display_name
    variable_group_name           = environment_key
    agent_pool_type               = local.is_self_hosted ? "self-hosted" : "microsoft-hosted"
    agent_pool_name               = local.is_self_hosted ? local.effective_agent_pool_name : "ubuntu-latest"
    service_connection_name_read  = "${local.resource_names.service_connection_name}-${environment_key}-read"
    service_connection_name_write = "${local.resource_names.service_connection_name}-${environment_key}-write"
    environment_name              = environment_key
    dependent_environment         = environment_value.dependent_environment
  } }
  files = local.template_folder != null ? { for file in fileset(local.template_folder, "**") : file => {
    name    = file
    content = file("${local.template_folder}/${file}")
  } } : {}
  main_repository_files = merge(local.files, local.pipeline_main_files)
  pipeline_main_files = local.pipeline_main_folder != null ? { for file in fileset(local.pipeline_main_folder, "**") : file => {
    name    = file
    content = templatefile("${local.pipeline_main_folder}/${file}", local.pipeline_main_replacements)
  } } : {}
  pipeline_main_folder = local.effective_pipeline_folder != null ? "${local.effective_pipeline_folder}/main" : null
  pipeline_main_replacements = {
    environments                     = local.environment_replacements
    project_name                     = local.azure_devops_project_name
    repository_name_templates        = local.effective_template_repo_name
    pipelines                        = local.effective_pipelines
    root_module_folder_relative_path = "."
    deployments                      = var.bicep_deployments != null ? var.bicep_deployments : []
  }
  pipeline_template_files = local.pipeline_template_folder != null ? { for file in fileset(local.pipeline_template_folder, "**") : file => {
    name    = file
    content = file("${local.pipeline_template_folder}/${file}")
  } } : {}
  pipeline_template_folder = local.effective_pipeline_folder != null ? "${local.effective_pipeline_folder}/templates" : null
  template_folder          = var.example_module_path
}

resource "azuredevops_git_repository_file" "this" {
  for_each = local.create_main_repository ? local.main_repository_files : {}

  repository_id       = azuredevops_git_repository.this[0].id
  file                = each.key
  content             = each.value.content
  branch              = local.default_branch
  commit_message      = "[skip ci]"
  overwrite_on_create = true
}

resource "azuredevops_git_repository_file" "template" {
  for_each = local.create_main_repository && local.create_template_repository ? local.pipeline_template_files : {}

  repository_id       = azuredevops_git_repository.template[0].id
  file                = each.key
  content             = each.value.content
  branch              = local.default_branch
  commit_message      = "[skip ci]"
  overwrite_on_create = true
}
