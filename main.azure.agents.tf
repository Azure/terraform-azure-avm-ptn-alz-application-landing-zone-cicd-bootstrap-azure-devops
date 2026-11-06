module "azure_devops_agents" {
  source  = "Azure/avm-ptn-cicd-agents-and-runners/azurerm"
  version = "0.6.0"
  count   = local.create_agent_container_instance_infrastructure ? 1 : 0

  location                                        = var.location
  postfix                                         = local.resource_names.agent_compute_postfix_name
  version_control_system_organization             = data.azuredevops_client_config.current.organization_url
  version_control_system_type                     = "azuredevops"
  compute_types                                   = [var.agent_compute_type]
  container_app_subnet_id                         = local.effective_agents_subnet_id
  container_instance_count                        = var.agent_container_instance_count
  container_instance_name_prefix                  = local.resource_names.container_instance_prefix_name
  container_instance_subnet_id                    = local.effective_agents_subnet_id
  container_instance_use_availability_zones       = var.agent_compute_use_availability_zones
  container_registry_name                         = local.resource_names.container_registry_name
  container_registry_private_endpoint_subnet_id   = local.effective_pe_subnet_id
  parent_id                                       = local.create_vnet_infrastructure ? module.resource_group["agents"].resource_id : null
  resource_group_creation_enabled                 = !local.create_vnet_infrastructure
  resource_group_name                             = local.create_vnet_infrastructure ? module.resource_group["agents"].name : null
  user_assigned_managed_identity_creation_enabled = var.agent_authentication_method == "uami" ? false : true
  user_assigned_managed_identity_id               = var.agent_authentication_method == "uami" ? module.agents_user_assigned_managed_identity[0].resource_id : null
  version_control_system_authentication_method    = var.agent_authentication_method
  version_control_system_personal_access_token    = var.agent_authentication_method == "pat" ? var.agent_personal_access_token : null
  version_control_system_pool_name                = azuredevops_agent_pool.this[0].name
  virtual_network_creation_enabled                = false
  virtual_network_id                              = local.effective_vnet_resource_id

  depends_on = [
    azuredevops_securityrole_assignment.agents_uami_pool_admin,
  ]
}

module "azure_managed_devops_pool" {
  source  = "Azure/avm-res-devopsinfrastructure-pool/azurerm"
  version = "0.3.2"
  count   = local.create_agent_managed_pool_infrastructure ? 1 : 0

  dev_center_project_resource_id = local.effective_dev_center_project_id
  location                       = var.location
  name                           = local.resource_names.devops_agent_pool_name
  resource_group_name            = module.resource_group["agents"].name
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = var.agent_authentication_method == "uami" ? [module.agents_user_assigned_managed_identity[0].resource_id] : []
  }
  maximum_concurrency = var.agent_container_instance_count
  organization_profile = {
    kind = "AzureDevOps"
    organizations = [
      {
        name = data.azuredevops_client_config.current.name
        projects = [
          local.azure_devops_project_name
        ]
      }
    ]
  }
  subnet_id = local.effective_agents_subnet_id
}
