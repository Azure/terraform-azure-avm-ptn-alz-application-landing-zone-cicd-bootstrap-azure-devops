variable "location" {
  type        = string
  description = "The location/region where the resources will be created. Must be in the short form (e.g. 'uksouth')"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "The location must only contain lowercase letters, numbers, and hyphens"
  }
  validation {
    condition     = length(var.location) <= 20
    error_message = "The location must be 20 characters or less"
  }
}

variable "organization_name" {
  type        = string
  description = "The name of the Azure DevOps organization."
}

variable "personal_access_token" {
  type        = string
  description = "The personal access token for the Azure DevOps organization."
  sensitive   = true
}

variable "pipeline_folder_path" {
  type        = string
  default     = null
  description = "The relative path to the folder containing pipeline YAML files to use. When null, auto-selects based on `deployment_mode` (e.g. 'pipelines/terraform' or 'pipelines/bicep'). Set to a custom path to use your own pipeline templates."
}

variable "private_endpoints_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for private endpoints (BYO mode). When set along with `agents_subnet_resource_id`, the module will not create a virtual network."
}

variable "address_space" {
  type        = string
  description = "The virtual network address space."
  default     = "10.0.0.0/24"
}

variable "agent_pool_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing Azure DevOps agent pool to use (BYO mode). When set, the module will not create an agent pool or any Azure compute infrastructure for agents. The provided pool name will be used in pipeline YAML files."
}

variable "agent_use_availability_zones" {
  type        = bool
  default     = false
  description = "Use availability zones for the agent pool if using container instances. This is off by default due to faults in various regions at time of authoring."
}

variable "agents_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for agents/runners (BYO mode). When set along with `private_endpoints_subnet_resource_id`, the module will not create a virtual network. The subnet must have the appropriate delegation for the chosen `self_hosted_agent_type`."
}

variable "alz_platform_landing_zone_mode_enabled" {
  type        = bool
  default     = false
  description = "When enabled, the module will not create private DNS zones and will not manage DNS zone groups for private endpoints. This is useful when the platform landing zone is managing DNS zones centrally via Azure Policy."
}

variable "approvers" {
  type        = map(string)
  description = "A map of approvers for the production environment. The key is the approver name and the value is the user principal name."
  default     = {}
}

variable "azure_devops_create_project" {
  type        = bool
  description = "Whether to create a new Azure DevOps project or use an existing one."
  default     = true
}

variable "azure_devops_project" {
  type        = string
  description = "The name of the existing Azure DevOps project. Required if azure_devops_create_project is false."
  default     = null
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "The deployment mode for the module. Possible values are 'terraform', 'bicep', or 'other'. Only 'terraform' mode creates the storage account for Terraform state."
  validation {
    condition     = contains(["terraform", "bicep", "other"], var.deployment_mode)
    error_message = "deployment_mode must be 'terraform', 'bicep', or 'other'."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "environments" {
  type = map(object({
    display_order                                = number
    display_name                                 = string
    has_approval                                 = optional(bool, false)
    dependent_environment                        = optional(string, "")
    resource_group_create                        = optional(bool, true)
    resource_group_name_template                 = optional(string, "rg-$${workload}-env-$${environment}-$${location}-$${sequence}")
    user_assigned_managed_identity_name_template = optional(string, "uami-$${workload}-$${environment}-$${type}-$${location}-$${sequence}")
  }))
  description = "A map of environments to create. Each environment has a display order, display name, optional approval settings, and optional resource group and managed identity naming templates."
  default = {
    dev = {
      display_order = 1
      display_name  = "Development"
    }
    test = {
      display_order         = 2
      display_name          = "Test"
      dependent_environment = "dev"
    }
    prod = {
      display_order         = 3
      display_name          = "Production"
      has_approval          = true
      dependent_environment = "test"
    }
  }
}

variable "example_module_path" {
  type        = string
  description = "The relative path to the example module to seed into the created repository."
  default     = null
}

variable "organization_name_prefix" {
  type        = string
  description = "The prefix for the Azure DevOps organization URL."
  default     = "https://dev.azure.com"
}

variable "repository_postfix" {
  type        = string
  description = "The postfix for the main repository name."
  default     = "demo"
}

variable "repository_postfix_template" {
  type        = string
  description = "The postfix for the template repository name."
  default     = "demo-template"
}

variable "resource_name_environment" {
  type        = string
  description = "The name segment for the environment."
  default     = "mgt"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_name_environment))
    error_message = "The name segment for the environment must only contain lowercase letters and numbers"
  }
  validation {
    condition     = length(var.resource_name_environment) <= 4
    error_message = "The name segment for the environment must be 4 characters or less"
  }
}

variable "resource_name_location_short" {
  type        = string
  description = "The short name segment for the location."
  default     = ""
  validation {
    condition     = length(var.resource_name_location_short) == 0 || can(regex("^[a-z]+$", var.resource_name_location_short))
    error_message = "The short name segment for the location must only contain lowercase letters"
  }
  validation {
    condition     = length(var.resource_name_location_short) <= 3
    error_message = "The short name segment for the location must be 3 characters or less"
  }
}

variable "resource_name_sequence_start" {
  type        = number
  description = "The number to use for the resource names."
  default     = 1
  validation {
    condition     = var.resource_name_sequence_start >= 1 && var.resource_name_sequence_start <= 999
    error_message = "The number must be between 1 and 999"
  }
}

variable "resource_name_templates" {
  type        = map(string)
  description = "A map of resource name templates to use for naming resources."
  default = {
    resource_group_state_name             = "rg-$${workload}-state-$${environment}-$${location}-$${sequence}"
    resource_group_agents_name            = "rg-$${workload}-agents-$${environment}-$${location}-$${sequence}"
    resource_group_identity_name          = "rg-$${workload}-identity-$${environment}-$${location}-$${sequence}"
    virtual_network_name                  = "vnet-$${workload}-$${environment}-$${location}-$${sequence}"
    network_security_group_name           = "nsg-$${workload}-$${environment}-$${location}-$${sequence}"
    nat_gateway_name                      = "nat-$${workload}-$${environment}-$${location}-$${sequence}"
    nat_gateway_public_ip_name            = "pip-nat-$${workload}-$${environment}-$${location}-$${sequence}"
    storage_account_name                  = "sto$${workload}$${environment}$${location_short}$${sequence}$${uniqueness}"
    storage_account_private_endpoint_name = "pe-sto-$${workload}-$${environment}-$${location}-$${sequence}"
    agent_compute_postfix_name            = "$${workload}-$${environment}-$${location_short}-$${sequence}"
    container_instance_prefix_name        = "aci-$${workload}-$${environment}-$${location}"
    container_registry_name               = "acr$${workload}$${environment}$${location_short}$${sequence}$${uniqueness}"
    project_name                          = "$${workload}-$${environment}"
    repository_main_name                  = "$${workload}-$${environment}-main"
    repository_template_name              = "$${workload}-$${environment}-template"
    agent_pool_name                       = "agent-pool-$${workload}-$${environment}"
    group_name                            = "group-$${workload}-$${environment}-approvers"
  }
}

variable "resource_name_workload" {
  type        = string
  description = "The name segment for the workload."
  default     = "dema"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_name_workload))
    error_message = "The name segment for the workload must only contain lowercase letters and numbers"
  }
  validation {
    condition     = length(var.resource_name_workload) <= 4
    error_message = "The name segment for the workload must be 4 characters or less"
  }
}

variable "self_hosted_agent_type" {
  type        = string
  description = "The type of self-hosted agent to use. Must be either 'azure_container_app' or 'azure_container_instance'."
  default     = "azure_container_instance"
  validation {
    condition     = contains(["azure_container_app", "azure_container_instance"], var.self_hosted_agent_type)
    error_message = "self_hosted_agent_type must be either 'azure_container_app' or 'azure_container_instance'."
  }
}

variable "subnets_and_sizes" {
  type        = map(number)
  description = "The size of the subnets."
  default = {
    agents            = 27
    private_endpoints = 29
  }
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "template_repository_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing template repository containing CI/CD pipeline templates (BYO mode). When set, the module will not create a template repository or push template files. The pipeline YAML in the main repository will reference this repository for templates."
}

variable "ci_template_path" {
  type        = string
  default     = null
  description = "The path to the CI template within the template repository. When null, defaults to 'ci-template.yaml'."
}

variable "cd_template_path" {
  type        = string
  default     = null
  description = "The path to the CD template within the template repository. When null, defaults to 'cd-template.yaml'."
}

variable "virtual_network_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing virtual network to use (BYO mode). Must be set together with `agents_subnet_resource_id` and `private_endpoints_subnet_resource_id`. When set, the module will not create a virtual network or agents resource group."
}

variable "use_self_hosted_agents" {
  type        = bool
  description = "Whether to use self-hosted agents."
  default     = true
}
