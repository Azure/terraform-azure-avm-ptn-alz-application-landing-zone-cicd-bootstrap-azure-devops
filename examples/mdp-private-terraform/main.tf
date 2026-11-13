terraform {
  required_version = "~> 1.9"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.15"
    }
    # tflint-ignore: terraform_unused_required_providers
    modtm = {
      source  = "registry.terraform.io/azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.6"
    }
  }
}

provider "azuredevops" {}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    storage {
      data_plane_available = false
    }
  }
  storage_use_azuread = true
}

resource "random_string" "workload" {
  length  = 4
  numeric = false
  special = false
  upper   = false
}

# Managed DevOps Pool with private networking and Terraform pipelines
module "test" {
  source = "../../"

  location               = var.location
  agent_compute_type     = "azure_devops_managed_pool"
  agent_use_self_hosted  = true
  enable_telemetry       = var.enable_telemetry
  example_module_path    = "${path.root}/../../example-repos/terraform"
  resource_name_workload = random_string.workload.result
}
