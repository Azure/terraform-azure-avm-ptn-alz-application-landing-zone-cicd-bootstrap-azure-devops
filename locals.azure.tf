# Azure infrastructure decision locals
locals {
  create_agent_infrastructure                    = var.agent_use_self_hosted && var.agent_existing_pool_name == null
  create_agent_managed_pool_infrastructure       = local.create_agent_infrastructure && var.agent_compute_type == "azure_devops_managed_pool"
  create_agent_container_instance_infrastructure = local.create_agent_infrastructure && var.agent_compute_type != "azure_devops_managed_pool"
  create_vnet_infrastructure                     = local.create_agent_infrastructure && var.azure_existing_virtual_network_resource_id == null
  create_dev_center_infrastructure               = local.create_agent_infrastructure && var.azure_existing_dev_center_project_resource_id == null
  default_audience_name                          = "api://AzureADTokenExchange"
  effective_agent_pool_name                      = var.agent_existing_pool_name != null ? var.agent_existing_pool_name : (local.create_agent_infrastructure ? azuredevops_agent_pool.this[0].name : "ubuntu-latest")
  effective_agents_subnet_id                     = var.azure_existing_agents_subnet_resource_id != null ? var.azure_existing_agents_subnet_resource_id : (local.create_vnet_infrastructure ? module.virtual_network[0].subnets["agents"].resource_id : null)
  effective_pe_subnet_id                         = var.azure_existing_private_endpoints_subnet_resource_id != null ? var.azure_existing_private_endpoints_subnet_resource_id : (local.create_vnet_infrastructure ? module.virtual_network[0].subnets["private_endpoints"].resource_id : null)
  effective_vnet_resource_id                     = var.azure_existing_virtual_network_resource_id != null ? var.azure_existing_virtual_network_resource_id : (local.create_vnet_infrastructure ? module.virtual_network[0].resource_id : null)
  effective_dev_center_project_id                = var.azure_existing_dev_center_project_resource_id != null ? var.azure_existing_dev_center_project_resource_id : (local.create_dev_center_infrastructure ? azapi_resource.dev_center_project[0].id : null)
  is_self_hosted                                 = var.agent_use_self_hosted || var.agent_existing_pool_name != null
  use_private_networking                         = var.azure_existing_virtual_network_resource_id != null || local.create_vnet_infrastructure
}
