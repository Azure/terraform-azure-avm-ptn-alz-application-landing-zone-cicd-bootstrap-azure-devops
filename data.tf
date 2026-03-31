data "azapi_client_config" "current" {}

locals {
  environment_subscription_ids = toset([for env in local.environments : env.subscription_id])
}

data "azapi_resource_action" "subscription" {
  for_each               = local.environment_subscription_ids
  action                 = ""
  method                 = "GET"
  resource_id            = "/subscriptions/${each.value}"
  type                   = "Microsoft.Resources/subscriptions@2022-12-01"
  response_export_values = ["displayName"]
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"
}
