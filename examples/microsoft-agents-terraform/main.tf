terraform {
  required_version = "~> 1.9"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.15"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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

# Microsoft-hosted agents with Terraform pipelines (no self-hosted infra)
module "test" {
  source = "../../"

  resource_name_workload = "msag"

  location              = var.location
  agent_use_self_hosted = false
  enable_telemetry      = var.enable_telemetry
  example_module_path   = "${path.root}/../../example-repos/terraform"
}
