# Calculate resource names
locals {
  name_replacements = {
    workload       = var.resource_name_workload
    environment    = var.resource_name_environment
    location       = var.location
    location_short = var.resource_name_location_short == "" ? module.regions.regions_by_name[var.location].geo_code : var.resource_name_location_short
    uniqueness     = random_string.unique_name.id
    sequence       = format("%03d", var.resource_name_sequence_start)
  }

  resource_names = { for key, value in var.resource_name_templates : key => templatestring(value, local.name_replacements) }
}

locals {
  default_audience_name          = "api://AzureADTokenExchange"
  organization_name_url          = "${var.organization_name_prefix}/${var.organization_name}"
  create_agent_infrastructure    = var.use_self_hosted_agents && var.agent_pool_name == null
  create_vnet_infrastructure     = local.create_agent_infrastructure && var.virtual_network_resource_id == null
  is_self_hosted                 = var.use_self_hosted_agents || var.agent_pool_name != null
  effective_agent_pool_name      = var.agent_pool_name != null ? var.agent_pool_name : (local.create_agent_infrastructure ? azuredevops_agent_pool.this[0].name : "ubuntu-latest")
  effective_vnet_resource_id     = var.virtual_network_resource_id != null ? var.virtual_network_resource_id : (local.create_vnet_infrastructure ? module.virtual_network[0].resource_id : null)
  effective_agents_subnet_id     = var.agents_subnet_resource_id != null ? var.agents_subnet_resource_id : (local.create_vnet_infrastructure ? module.virtual_network[0].subnets["agents"].resource_id : null)
  effective_pe_subnet_id         = var.private_endpoints_subnet_resource_id != null ? var.private_endpoints_subnet_resource_id : (local.create_vnet_infrastructure ? module.virtual_network[0].subnets["private_endpoints"].resource_id : null)
  use_private_networking         = local.effective_vnet_resource_id != null
  create_template_repository     = var.template_repository_name == null
  effective_template_repo_name   = var.template_repository_name != null ? var.template_repository_name : azuredevops_git_repository.template[0].name
  effective_ci_template_path     = coalesce(var.ci_template_path, "ci-template.yaml")
  effective_cd_template_path     = coalesce(var.cd_template_path, "cd-template.yaml")
  create_approval_group          = var.approvers_group_origin_id == null && length(var.approvers) > 0
  effective_approvers_origin_id  = var.approvers_group_origin_id != null ? var.approvers_group_origin_id : (local.create_approval_group ? azuredevops_group.this[0].origin_id : null)
  has_approvers                  = var.approvers_group_origin_id != null || length(var.approvers) > 0
}

locals {
  environments = { for key, value in var.environments : key => {
    display_order         = value.display_order
    display_name          = value.display_name
    has_approval          = value.has_approval
    dependent_environment = value.dependent_environment
    scope                 = value.scope
    subscription_id       = coalesce(value.subscription_id, data.azapi_client_config.current.subscription_id)
    resource_id           = value.resource_id
    create_resource_group = value.scope == "resource_group" && value.resource_id == null && value.resource_group_create
    plan_role_definition_id_or_name  = value.plan_role_definition_id_or_name
    apply_role_definition_id_or_name = value.apply_role_definition_id_or_name
    resource_group_name = templatestring(value.resource_group_name_template, {
      workload    = local.name_replacements.workload
      environment = key
      location    = local.name_replacements.location
      sequence    = local.name_replacements.sequence
    })
    user_assigned_managed_identity_name_template = value.user_assigned_managed_identity_name_template
  } }
  environment_split_type = {
    plan  = "plan"
    apply = "apply"
  }
  environment_split = { for environment_split in flatten([for env_key, env_value in local.environments : [
    for split_key, split_value in local.environment_split_type : {
      composite_key      = "${env_key}-${split_key}"
      environment        = env_key
      type               = split_key
      required_templates = split_key == local.environment_split_type.plan ? ["ci-template.yaml", "cd-template.yaml"] : ["cd-template.yaml"]
      user_assigned_managed_identity_name = templatestring(env_value.user_assigned_managed_identity_name_template, {
        workload    = local.name_replacements.workload
        environment = env_key
        type        = split_key
        location    = local.name_replacements.location
        sequence    = local.name_replacements.sequence
      })
    }
  ]]) : environment_split.composite_key => environment_split }
}
