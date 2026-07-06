output "agent_pool_name" {
  description = "The Azure DevOps agent pool name used by this deployment."
  value       = var.agent_existing_pool_name != null ? var.agent_existing_pool_name : (local.create_agent_infrastructure ? azuredevops_agent_pool.this[0].name : null)
}

output "approvers" {
  description = "The list of approver descriptors matched from the organization."
  value       = tolist(local.approvers)
}

output "managed_identity_client_ids" {
  description = "A map of managed identity client IDs for each environment split (plan/apply)."
  value       = local.create_main_repository ? { for env_key, env_value in local.environment_split : env_key => module.user_assigned_managed_identity[env_key].client_id } : {}
}

output "resource_id" {
  description = "The resource ID of the Azure DevOps project that this module bootstraps."
  value       = local.azure_devops_project_id
}

output "subscription_id" {
  description = "The subscription ID."
  value       = data.azapi_client_config.current.subscription_id
}

output "subscription_name" {
  description = "The subscription display name."
  value       = data.azapi_resource_action.subscription[data.azapi_client_config.current.subscription_id].output.displayName
}

output "tenant_id" {
  description = "The tenant ID."
  value       = data.azapi_client_config.current.tenant_id
}
