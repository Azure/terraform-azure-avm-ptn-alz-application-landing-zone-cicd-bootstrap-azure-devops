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

# ACI with private networking and Terraform pipelines
module "test" {
  source = "../../"

  location              = var.location
  organization_name     = var.organization_name
  enable_telemetry      = var.enable_telemetry
  example_module_path   = "examples/terraform-example-module"
  self_hosted_agent_type = "azure_container_instance"
  use_self_hosted_agents = true
}
