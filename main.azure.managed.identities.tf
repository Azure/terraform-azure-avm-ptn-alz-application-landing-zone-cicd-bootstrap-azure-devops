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
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  # Azure serialises federated identity credential writes per managed identity. When several
  # credentials are created for the same user-assigned identity in parallel (Terraform's default
  # concurrency), Azure returns a 409 "ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity".
  # Retry (with the provider's default backoff + randomisation, which desynchronises sibling writers)
  # so the credentials serialise and eventually succeed without failing the run.
  retry = {
    error_message_regex = ["ConcurrentFederatedIdentityCredentialsWritesForSingleManagedIdentity"]
  }
}
