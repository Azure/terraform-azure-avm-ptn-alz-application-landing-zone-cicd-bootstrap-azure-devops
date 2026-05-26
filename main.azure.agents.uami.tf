module "agents_user_assigned_managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.0"
  count   = local.create_agent_infrastructure && var.agent_authentication_method == "uami" ? 1 : 0

  location            = var.location
  name                = local.resource_names.agent_user_assigned_managed_identity_name
  resource_group_name = module.resource_group["identity"].name
}

resource "time_sleep" "agents_user_assigned_managed_identity_propagation" {
  count = local.create_agent_infrastructure && var.agent_authentication_method == "uami" ? 1 : 0

  create_duration = "30s"
  triggers = {
    user_assigned_managed_identity_id = module.agents_user_assigned_managed_identity[0].resource_id
  }
}

resource "azuredevops_service_principal_entitlement" "agents_user_assigned_managed_identity" {
  count = local.create_agent_infrastructure && var.agent_authentication_method == "uami" ? 1 : 0

  origin               = "aad"
  origin_id            = module.agents_user_assigned_managed_identity[0].principal_id
  account_license_type = "express"

  depends_on = [time_sleep.agents_user_assigned_managed_identity_propagation]
}

resource "azuredevops_securityrole_assignment" "agents_uami_pool_admin" {
  count = local.create_agent_infrastructure && var.agent_authentication_method == "uami" ? 1 : 0

  scope       = "distributedtask.agentpoolrole"
  resource_id = azuredevops_agent_pool.this[0].id
  role_name   = "Administrator"
  identity_id = azuredevops_service_principal_entitlement.agents_user_assigned_managed_identity[0].id
}
