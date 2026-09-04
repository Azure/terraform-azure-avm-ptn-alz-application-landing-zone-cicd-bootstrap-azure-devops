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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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

# ACA with Bicep pipelines
module "test" {
  source = "../../"

  location               = var.location
  agent_compute_type     = "azure_container_app"
  agent_use_self_hosted  = true
  deployment_mode        = "bicep"
  enable_telemetry       = var.enable_telemetry
  example_module_path    = "${path.root}/../../example-repos/bicep"
  resource_name_workload = random_string.workload.result
}
