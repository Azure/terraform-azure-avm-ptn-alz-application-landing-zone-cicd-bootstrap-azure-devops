data "azapi_client_config" "current" {}

data "azapi_resource_action" "current_subscription" {
  type        = "Microsoft.Resources/subscriptions@2022-12-01"
  resource_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  action      = ""
  method      = "GET"
  response_export_values = ["displayName"]
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"
}
