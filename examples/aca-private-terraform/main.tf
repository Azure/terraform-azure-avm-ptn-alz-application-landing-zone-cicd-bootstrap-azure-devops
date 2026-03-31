terraform {
  required_version = "~> 1.9"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.7"
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

provider "azurerm" {
  features {}
}

# ACA with private networking and Terraform pipelines
module "test" {
  source = "../../"

  azuredevops_organization_name = var.azuredevops_organization_name
  location                      = var.location
  agent_use_self_hosted         = true
  compute_type                  = "azure_container_app"
  enable_telemetry              = var.enable_telemetry
  example_module_path           = "examples/example-module-terraform"
}
