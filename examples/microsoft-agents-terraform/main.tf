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

# Microsoft-hosted agents with Terraform pipelines (no self-hosted infra)
module "test" {
  source = "../../"

  location               = var.location
  organization_name      = var.organization_name
  enable_telemetry       = var.enable_telemetry
  example_module_path    = "examples/terraform-example-module"
  use_self_hosted_agents = false
}
