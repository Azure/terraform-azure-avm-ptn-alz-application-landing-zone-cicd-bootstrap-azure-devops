output "managed_identity_client_ids" {
  description = "A map of managed identity client IDs for each environment split (plan/apply)."
  value       = { for env_key, env_value in local.environment_split : env_key => module.user_assigned_managed_identity[env_key].client_id }
}

output "subscription_id" {
  description = "The subscription ID of the current Azure subscription."
  value       = data.azapi_client_config.current.subscription_id
}

output "subscription_name" {
  description = "The display name of the current Azure subscription."
  value       = data.azapi_resource_action.current_subscription.output.displayName
}

output "tenant_id" {
  description = "The tenant ID of the current Azure subscription."
  value       = data.azapi_client_config.current.tenant_id
}
