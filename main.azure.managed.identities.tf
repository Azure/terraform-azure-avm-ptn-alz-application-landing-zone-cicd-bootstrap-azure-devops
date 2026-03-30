module "user_assigned_managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.0"

  for_each            = local.environment_split
  location            = var.location
  name                = each.value.user_assigned_managed_identity_name
  resource_group_name = module.resource_group["identity"].name
}

resource "azapi_resource" "federated_identity_credential" {
  for_each  = local.environment_split
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  name      = "${var.organization_name}-${local.azure_devops_project_name}-${each.key}"
  parent_id = module.user_assigned_managed_identity[each.key].resource_id
  body = {
    properties = {
      audiences = [local.default_audience_name]
      issuer    = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_issuer
      subject   = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_subject
    }
  }
}
