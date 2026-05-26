# Environment processing locals
locals {
  environment_split = { for identity in flatten([for env_key, env_value in local.environments : [
    for identity_key, identity_value in {
      for k, v in { read = env_value.identities.read, write = env_value.identities.write } : k => v if v.enabled
      } : {
      composite_key      = "${env_key}-${identity_key}"
      environment        = env_key
      type               = identity_key
      role_assignments   = identity_value.role_assignments
      has_approval       = env_value.has_approval
      required_templates = local.effective_template_repo_name != "" ? [for k in coalesce(identity_value.allowed_template_keys, identity_key == "read" ? ["ci", "cd"] : ["cd"]) : local.effective_pipelines[k].template_path if contains(keys(local.effective_pipelines), k)] : []
      user_assigned_managed_identity_name = coalesce(
        identity_value.name,
        templatestring(local.resource_names["identity_${identity_key}_name"], merge(local.name_replacements, {
          environment = env_key
        }))
      )
      service_connection_name   = "${local.resource_names.service_connection_name}-${env_key}-${identity_key}"
      federated_credential_name = "${local.resource_names.federated_credential_name}-${env_key}-${identity_key}"
    }
  ]]) : identity.composite_key => identity }
  environments = { for key, value in var.environments : key => {
    display_order         = value.display_order
    display_name          = value.display_name
    has_approval          = value.has_approval
    dependent_environment = value.dependent_environment
    scope                 = value.scope
    subscription_id       = coalesce(value.subscription_id, data.azapi_client_config.current.subscription_id)
    resource_id           = coalesce(value.resource_id, value.scope == "subscription" ? "/subscriptions/${coalesce(value.subscription_id, data.azapi_client_config.current.subscription_id)}" : null)
    create_resource_group = value.scope == "resource_group" && value.resource_id == null && value.resource_group_create
    identities            = value.identities
    resource_group_name = coalesce(value.resource_group_name, templatestring(local.resource_names.resource_group_env_name, merge(local.name_replacements, {
      environment = key
    })))
  } }
}
