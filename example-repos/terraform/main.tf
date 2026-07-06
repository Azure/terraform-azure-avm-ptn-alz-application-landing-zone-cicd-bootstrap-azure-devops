module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"
  count   = var.resource_group_create ? 1 : 0

  location = var.location
  name     = local.resource_names.resource_group_name
  tags     = var.tags
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  address_space       = var.virtual_network_address_space
  location            = var.location
  resource_group_name = local.resource_group_name
  name                = local.resource_names.virtual_network_name
  subnets             = var.virtual_network_subnets
  tags                = var.tags
}

module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.18.1"

  location = var.location
  name     = local.resource_names.virtual_machine_name
  network_interfaces = {
    private = {
      name = local.resource_names.network_interface_name
      ip_configurations = {
        private = {
          name                          = local.resource_names.network_interface_name
          private_ip_subnet_resource_id = module.virtual_network.subnets["example"].resource_id
        }
      }
    }
  }
  resource_group_name        = local.resource_group_name
  zone                       = "1"
  encryption_at_host_enabled = false
  os_type                    = "linux"
  sku_size                   = var.virtual_machine_sku
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  tags = var.tags
}
