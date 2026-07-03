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

locals {
  byo_environment  = "test"
  seed_environment = "seed"
}

resource "random_string" "workload" {
  length  = 4
  numeric = false
  special = false
  upper   = false
}

# Seed deployment: create self-hosted agent infrastructure including an agent pool.
module "seed" {
  source = "../../"

  location                               = var.location
  azuredevops_create_main_repository     = false
  azuredevops_create_template_repository = false
  enable_telemetry                       = var.enable_telemetry
  resource_name_environment              = local.seed_environment
  resource_name_workload                 = random_string.workload.result
}

# BYO deployment: consume the agent pool from the seed module.
module "test" {
  source = "../../"

  location                  = var.location
  agent_existing_pool_name  = module.seed.agent_pool_name
  enable_telemetry          = var.enable_telemetry
  example_module_path       = "${path.root}/../../example-repos/terraform"
  resource_name_environment = local.byo_environment
  resource_name_workload    = random_string.workload.result
}
