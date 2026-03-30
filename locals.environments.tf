# Default identity configurations based on deployment mode
locals {
  default_identities = contains(["terraform", "bicep"], var.deployment_mode) ? {
    read = {
      role_definition_id_or_name = "Reader"
    }
    write = {
      role_definition_id_or_name = "Contributor"
    }
  } : {
    write = {
      role_definition_id_or_name = "Contributor"
    }
  }
}

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
    identities            = coalesce(value.identities, local.default_identities)
    resource_group_name = templatestring(value.resource_group_name_template, {
      workload    = local.name_replacements.workload
      environment = key
      location    = local.name_replacements.location
      sequence    = local.name_replacements.sequence
    })
    user_assigned_managed_identity_name_template = value.user_assigned_managed_identity_name_template
  } }

  environment_split = { for identity in flatten([for env_key, env_value in local.environments : [
    for identity_key, identity_value in env_value.identities : {
      composite_key                  = "${env_key}-${identity_key}"
      environment                    = env_key
      type                           = identity_key
      role_definition_id_or_name     = identity_value.role_definition_id_or_name
      has_approval                   = env_value.has_approval
      required_templates             = identity_key == "read" ? ["ci-template.yaml", "cd-template.yaml"] : ["cd-template.yaml"]
      user_assigned_managed_identity_name = templatestring(env_value.user_assigned_managed_identity_name_template, {
        workload    = local.name_replacements.workload
        environment = env_key
        type        = identity_key
        location    = local.name_replacements.location
        sequence    = local.name_replacements.sequence
      })
      service_connection_name   = "${local.resource_names.service_connection_name}-${env_key}-${identity_key}"
      federated_credential_name = "${local.resource_names.federated_credential_name}-${env_key}-${identity_key}"
    }
  ]]) : identity.composite_key => identity }
}