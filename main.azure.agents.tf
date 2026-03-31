module "azure_devops_agents" {
  source  = "Azure/avm-ptn-cicd-agents-and-runners/azurerm"
  version = "0.5.2"
  count   = local.create_agent_infrastructure ? 1 : 0

  location                                      = var.location
  postfix                                       = local.resource_names.agent_compute_postfix_name
  version_control_system_organization           = data.azuredevops_client_config.current.organization_url
  version_control_system_type                   = "azuredevops"
  compute_types                                 = [var.agent_compute_type]
  container_app_subnet_id                       = local.effective_agents_subnet_id
  container_instance_count                      = 4
  container_instance_name_prefix                = local.resource_names.container_instance_prefix_name
  container_instance_subnet_id                  = local.effective_agents_subnet_id
  container_instance_use_availability_zones     = var.agent_compute_use_availability_zones
  container_registry_name                       = local.resource_names.container_registry_name
  container_registry_private_endpoint_subnet_id = local.effective_pe_subnet_id
  resource_group_creation_enabled               = !local.create_vnet_infrastructure
  resource_group_name                           = local.create_vnet_infrastructure ? module.resource_group["agents"].name : null
  version_control_system_authentication_method  = var.agent_authentication_method
  version_control_system_personal_access_token  = var.agent_authentication_method == "pat" ? var.agent_personal_access_token : null
  version_control_system_pool_name              = azuredevops_agent_pool.this[0].name
  virtual_network_creation_enabled              = false
  virtual_network_id                            = local.effective_vnet_resource_id

  depends_on = [azuredevops_pipeline_authorization.service_connection, azuredevops_pipeline_authorization.environment, azuredevops_pipeline_authorization.agent_pool]
}
