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

# This is the module call
module "test" {
  source = "../../"

  azuredevops_organization_name = var.azuredevops_organization_name
  # source             = "Azure/avm-ptn-alz-application-landing-zone-cicd-bootstrap-azure-devops/azurerm"
  location            = var.location
  enable_telemetry    = var.enable_telemetry
  example_module_path = "examples/example-module-terraform"
}
