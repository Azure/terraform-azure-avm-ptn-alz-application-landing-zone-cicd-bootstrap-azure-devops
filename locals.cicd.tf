# Azure DevOps CI/CD decision locals
locals {
  create_approval_group         = var.azuredevops_existing_approvers_group_origin_id == null && length(var.approvers) > 0
  create_main_repository        = var.azuredevops_create_main_repository
  create_template_repository    = local.create_main_repository && var.azuredevops_create_template_repository && var.azuredevops_existing_template_repository_name == null
  effective_approvers_origin_id = var.azuredevops_existing_approvers_group_origin_id != null ? var.azuredevops_existing_approvers_group_origin_id : (local.create_approval_group ? azuredevops_group.this[0].origin_id : null)
  effective_pipelines = coalesce(var.azuredevops_pipelines, {
    ci = { main_file = "ci.yaml", template_path = "ci-template.yaml" }
    cd = { main_file = "cd.yaml", template_path = "cd-template.yaml" }
  })
  effective_template_repo_name = var.azuredevops_existing_template_repository_name != null ? var.azuredevops_existing_template_repository_name : (
    local.create_template_repository ? azuredevops_git_repository.template[0].name : ""
  )
  has_approvers     = var.azuredevops_existing_approvers_group_origin_id != null || length(var.approvers) > 0
  has_template_repo = var.azuredevops_existing_template_repository_name != null || local.create_template_repository

  plan_storage_container_backend_collisions = [
    for container_name in values(local.plan_storage_container_names) : container_name
    if contains(keys(local.environments), container_name)
  ]
  plan_storage_container_duplicate_names = [
    for name in distinct(values(local.plan_storage_container_names)) : name
    if length([for v in values(local.plan_storage_container_names) : v if v == name]) > 1
  ]
  plan_storage_container_names = var.deployment_mode == "terraform" && var.use_storage_account_for_plan ? { for env_key, env_value in local.environments : env_key => (
    length(env_key) <= 56 ? "${env_key}-tfplan" : "tfplan-${substr(sha256(env_key), 0, 32)}"
  ) } : {}
}
