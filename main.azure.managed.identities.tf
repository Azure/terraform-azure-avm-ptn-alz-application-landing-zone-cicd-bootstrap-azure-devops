module "user_assigned_managed_identity" {
  source   = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version  = "0.5.0"
  for_each = local.environment_split

  location            = var.location
  name                = each.value.user_assigned_managed_identity_name
  resource_group_name = module.resource_group["identity"].name
}

resource "azapi_resource" "federated_identity_credential" {
  for_each = local.create_main_repository ? local.environment_split : {}

  name      = each.value.federated_credential_name
  parent_id = module.user_assigned_managed_identity[each.key].resource_id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  body = {
    properties = {
      audiences = [local.default_audience_name]
      issuer    = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_issuer
      subject   = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_subject
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Azure serialises federated identity credential writes per managed identity. When several
  # credentials are created for the same user-assigned identity in parallel (Terraform's default
  # concurrency), Azure returns a 409 "ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity".
  # Retry (with the provider's default backoff + randomisation, which desynchronises sibling writers)
  # so the credentials serialise and eventually succeed without failing the run.
  retry = {
    error_message_regex = ["ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity"]
  }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  # Ensure the federated identity credential is destroyed (and given time to propagate out of Entra)
  # before the backing Azure DevOps service connection is deleted. See time_sleep below.
  depends_on = [time_sleep.service_connection_teardown]
}

# Azure DevOps refuses to delete a workload-identity-federation service connection while federated
# identity credentials for its backing identity still exist in the Entra tenant ("Cannot delete this
# service connection while federated credentials for app <id> exist in Entra tenant"). On destroy
# Terraform removes the federated identity credential before the service connection (the credential
# references the connection), but the Entra deletion is eventually consistent and may not have
# propagated by the time the service connection delete runs, causing an intermittent teardown failure.
# This time_sleep sits between the credential and the connection in the dependency graph: the trigger
# makes it depend on the service connection (created after it, destroyed before it) and the credential
# depends_on it, so on destroy it enforces a delay after the credential is removed and before the
# connection is deleted, giving Entra time to propagate the deletion. It adds no create-time delay.
resource "time_sleep" "service_connection_teardown" {
  for_each = local.create_main_repository ? local.environment_split : {}

  destroy_duration = "90s"
  triggers = {
    service_connection_id = azuredevops_serviceendpoint_azurerm.this[each.key].id
  }
}
