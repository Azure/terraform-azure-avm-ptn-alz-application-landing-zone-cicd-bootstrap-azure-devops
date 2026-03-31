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

# Minimal example: single write identity, public agents, no template repo, custom pipeline
module "test" {
  source = "../../"

  location                     = var.location
  azuredevops_organization_name = var.azuredevops_organization_name
  deployment_mode              = "other"
  agent_use_self_hosted        = false

  azuredevops_existing_template_repository_name = "not-used"

  azuredevops_pipeline_folder_path = "pipelines"
  azuredevops_pipelines = {
    info = {
      main_file     = "info.yaml"
      template_path = "info-template.yaml"
    }
  }

  environments = {
    dev = {
      display_order   = 1
      display_name    = "Development"
      scope           = "subscription"
      subscription_id = var.target_subscription_id
      identities = {
        read = { enabled = false }
      }
    }
  }
}
