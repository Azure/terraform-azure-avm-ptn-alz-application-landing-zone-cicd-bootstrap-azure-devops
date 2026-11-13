resource "azapi_resource" "azure_dev_center" {
  count = local.create_dev_center_infrastructure ? 1 : 0

  location  = var.location
  name      = local.resource_names.dev_center_name
  parent_id = module.resource_group["agents"].resource_id
  type      = "Microsoft.DevCenter/devCenters@2025-02-01"
  body      = {}
  tags      = var.tags
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
      devCenterId        = azapi_resource.azure_dev_center[0].id
      maxDevBoxesPerUser = 0
    }
  }
  response_export_values = []
  tags                   = var.tags
}
