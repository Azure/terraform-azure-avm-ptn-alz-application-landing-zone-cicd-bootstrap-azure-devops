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

# ACI with private networking and Terraform pipelines
module "test" {
  source = "../../"

  location              = var.location
  agent_compute_type    = "azure_container_instance"
  agent_use_self_hosted = true
  enable_telemetry      = var.enable_telemetry
  example_module_path   = "${path.root}/../../example-repos/terraform"
}
