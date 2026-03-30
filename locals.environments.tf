# Environment processing locals
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
    identities            = value.identities
    resource_group_name = coalesce(value.resource_group_name, templatestring(local.resource_names.resource_group_env_name, {
      workload    = local.name_replacements.workload
      environment = key
      location    = local.name_replacements.location
      sequence    = local.name_replacements.sequence
    }))
  } }

  environment_split = { for identity in flatten([for env_key, env_value in local.environments : [
    for identity_key, identity_value in {
      for k, v in { read = env_value.identities.read, write = env_value.identities.write } : k => v if v.enabled
    } : {
      composite_key              = "${env_key}-${identity_key}"
      environment                = env_key
      type                       = identity_key
      role_assignments            = identity_value.role_assignments
      has_approval               = env_value.has_approval
      required_templates         = [for k in coalesce(identity_value.allowed_template_keys, identity_key == "read" ? keys(local.effective_pipelines) : ["cd"]) : local.effective_pipelines[k].template_path if contains(keys(local.effective_pipelines), k)]
      user_assigned_managed_identity_name = coalesce(
        identity_value.name,
        templatestring(local.resource_names["identity_${identity_key}_name"], {
          workload    = local.name_replacements.workload
          environment = env_key
          location    = local.name_replacements.location
          sequence    = local.name_replacements.sequence
        })
      )
      service_connection_name   = "${local.resource_names.service_connection_name}-${env_key}-${identity_key}"
      federated_credential_name = "${local.resource_names.federated_credential_name}-${env_key}-${identity_key}"
    }
  ]]) : identity.composite_key => identity }
}
