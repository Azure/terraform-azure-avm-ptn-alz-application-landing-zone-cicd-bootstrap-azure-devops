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
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
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

# BYO agent pool with Terraform pipelines (no self-hosted infra created)
module "test" {
  source = "../../"

  location                 = var.location
  agent_existing_pool_name = "my-existing-agent-pool"
  enable_telemetry         = var.enable_telemetry
  example_module_path      = "${path.root}/../../example-repos/terraform"
}
