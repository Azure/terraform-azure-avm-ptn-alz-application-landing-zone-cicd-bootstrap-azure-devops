module "azure_dev_center" {
  source  = "Azure/avm-res-devcenter-devcenter/azurerm"
  version = "0.2.0"
  count   = local.create_dev_center_infrastructure ? 1 : 0

  dev_center_name     = local.resource_names.dev_center_name
  location            = var.location
  resource_group_name = module.resource_group["agents"].name
  tags                = var.tags
}

resource "azapi_resource" "dev_center_project" {
  count = local.create_dev_center_infrastructure ? 1 : 0

  location  = var.location
  name      = local.resource_names.dev_center_project_name
  parent_id = module.resource_group["agents"].resource_id
  type      = "Microsoft.DevCenter/projects@2025-02-01"
  body = {
    properties = {
      description        = "Dev Center Project for the workload ${var.resource_name_workload}"
      devCenterId        = module.azure_dev_center[0].resource_id
      maxDevBoxesPerUser = 0
    }
  }
  response_export_values = []
  tags                   = var.tags
}
