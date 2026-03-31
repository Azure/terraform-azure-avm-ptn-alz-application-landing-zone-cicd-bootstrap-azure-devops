# Example Terraform Repository

This is sample Terraform code that gets seeded into the repository created by this module. It is intended as a starting point that users can customize for their own infrastructure deployments.

## Resources Deployed

- **Resource Group** — using [avm-res-resources-resourcegroup](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest)
- **Virtual Network** (with subnets) — using [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest)
- **Virtual Machine** (Ubuntu Linux) — using [avm-res-compute-virtualmachine](https://registry.terraform.io/modules/Azure/avm-res-compute-virtualmachine/azurerm/latest)

## Configuration

Environment-specific variable values are provided via `.tfvars` files in the `config/` directory (e.g. `dev.tfvars`, `test.tfvars`, `prod.tfvars`).
