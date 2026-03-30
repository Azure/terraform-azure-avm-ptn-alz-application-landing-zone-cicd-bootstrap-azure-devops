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

# ACA with Bicep pipelines
module "test" {
  source = "../../"

  location               = var.location
  azuredevops_organization_name      = var.azuredevops_organization_name
  enable_telemetry       = var.enable_telemetry
  deployment_mode        = "bicep"
  example_module_path    = "examples/example-module-bicep"
  compute_type = "azure_container_app"
  agent_use_self_hosted = true
}
