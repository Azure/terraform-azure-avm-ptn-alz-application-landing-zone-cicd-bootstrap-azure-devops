# Azure DevOps CI/CD decision locals
locals {
  organization_name_url          = "${var.azuredevops_organization_url_prefix}/${var.azuredevops_organization_name}"
  create_template_repository     = var.azuredevops_existing_template_repository_name == null
  effective_template_repo_name   = var.azuredevops_existing_template_repository_name != null ? var.azuredevops_existing_template_repository_name : azuredevops_git_repository.template[0].name
  effective_pipelines = coalesce(var.azuredevops_pipelines, {
    ci = { main_file = "ci.yaml", template_path = "ci-template.yaml" }
    cd = { main_file = "cd.yaml", template_path = "cd-template.yaml" }
  })
  create_approval_group          = var.azuredevops_existing_approvers_group_origin_id == null && length(var.approvers) > 0
  effective_approvers_origin_id  = var.azuredevops_existing_approvers_group_origin_id != null ? var.azuredevops_existing_approvers_group_origin_id : (local.create_approval_group ? azuredevops_group.this[0].origin_id : null)
  has_approvers                  = var.azuredevops_existing_approvers_group_origin_id != null || length(var.approvers) > 0
}
