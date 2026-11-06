resource "azuredevops_agent_pool" "this" {
  count = local.create_agent_container_instance_infrastructure ? 1 : 0

  name           = local.resource_names.agent_pool_name
  auto_provision = false
  auto_update    = true
}

data "azuredevops_agent_queue" "this" {
  count = local.create_agent_managed_pool_infrastructure ? 1 : 0

  project_id = local.azure_devops_project_id
  name       = module.azure_managed_devops_pool[0].name

  depends_on = [module.azure_managed_devops_pool]
}

resource "azuredevops_agent_queue" "this" {
  count = local.create_agent_container_instance_infrastructure ? 1 : 0

  project_id    = local.azure_devops_project_id
  agent_pool_id = local.effective_agent_pool_id
}

locals {
  effective_agent_pool_id  = local.create_agent_container_instance_infrastructure ? azuredevops_agent_pool.this[0].id : module.azure_managed_devops_pool[0].resource_id
  effective_agent_queue_id = local.create_agent_container_instance_infrastructure ? azuredevops_agent_queue.this[0].id : data.azuredevops_agent_queue.this[0].id
}
