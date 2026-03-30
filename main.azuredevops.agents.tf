resource "azuredevops_agent_pool" "this" {
  count          = local.create_agent_infrastructure ? 1 : 0
  name           = local.resource_names.agent_pool_name
  auto_provision = false
  auto_update    = true
}

resource "azuredevops_agent_queue" "this" {
  count         = local.create_agent_infrastructure ? 1 : 0
  project_id    = local.azure_devops_project_id
  agent_pool_id = azuredevops_agent_pool.this[0].id
}
