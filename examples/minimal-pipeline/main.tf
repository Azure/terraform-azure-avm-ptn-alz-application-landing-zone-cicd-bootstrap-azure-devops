terraform {
  required_version = "~> 1.9"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
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

data "azapi_client_config" "current" {}

# Minimal example: single write identity, public agents, no template repo, custom pipeline
module "test" {
  source = "../../"

  azuredevops_organization_name          = var.azuredevops_organization_name
  location                               = var.location
  agent_use_self_hosted                  = false
  azuredevops_create_template_repository = false
  azuredevops_pipeline_folder_path       = "${path.root}/pipelines"
  azuredevops_pipelines = {
    info = {
      main_file     = "info.yaml"
      template_path = "info-template.yaml"
    }
  }
  deployment_mode = "other"
  environments = {
    dev = {
      display_order   = 1
      display_name    = "Development"
      scope           = "subscription"
      subscription_id = data.azapi_client_config.current.subscription_id
      identities = {
        read = { enabled = false }
      }
    }
  }
}
