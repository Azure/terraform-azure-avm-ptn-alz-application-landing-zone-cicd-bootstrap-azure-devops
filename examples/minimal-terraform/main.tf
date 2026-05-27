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

# This is the module call
module "test" {
  source = "../../"

  # source             = "Azure/avm-ptn-alz-application-landing-zone-cicd-bootstrap-azure-devops/azurerm"
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  example_module_path = "${path.root}/../../example-repos/terraform"
}
