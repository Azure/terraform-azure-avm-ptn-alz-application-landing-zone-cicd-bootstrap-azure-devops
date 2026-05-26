variable "agent_authentication_method" {
  type        = string
  default     = "uami"
  description = "The authentication method for self-hosted agents. Possible values are 'pat' or 'uami'. UAMI (User Assigned Managed Identity) does not require a PAT for agent authentication."

  validation {
    condition     = contains(["pat", "uami"], var.agent_authentication_method)
    error_message = "agent_authentication_method must be 'pat' or 'uami'."
  }
}

variable "agent_compute_type" {
  type        = string
  default     = "azure_container_instance"
  description = "The type of Azure compute to use for self-hosted agents. Must be either 'azure_container_app' or 'azure_container_instance'."

  validation {
    condition     = contains(["azure_container_app", "azure_container_instance"], var.agent_compute_type)
    error_message = "agent_compute_type must be either 'azure_container_app' or 'azure_container_instance'."
  }
}

variable "agent_compute_use_availability_zones" {
  type        = bool
  default     = false
  description = "Use availability zones for the compute instances. This is off by default due to faults in various regions at time of authoring."
}

variable "agent_container_instance_count" {
  type        = number
  default     = 4
  description = "The number of container instances to provision when `agent_compute_type` is 'azure_container_instance'. Ignored when `agent_compute_type` is 'azure_container_app'."

  validation {
    condition     = var.agent_container_instance_count >= 1
    error_message = "agent_container_instance_count must be greater than or equal to 1."
  }
}

variable "agent_existing_pool_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing Azure DevOps agent pool (BYO mode). When set, the module will not create an agent pool or any Azure compute infrastructure. The provided pool name will be used in pipeline YAML files."
}

variable "agent_use_self_hosted" {
  type        = bool
  default     = true
  description = "Whether to use self-hosted agents. When false, pipelines use Microsoft-hosted agents."
}

variable "azure_address_space" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The virtual network address space."
}

variable "azure_alz_platform_landing_zone_mode_enabled" {
  type        = bool
  default     = false
  description = "When enabled, the module will not create private DNS zones and will not manage DNS zone groups for private endpoints. This is useful when the platform landing zone is managing DNS zones centrally via Azure Policy."
}

variable "azure_existing_agents_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for agents (BYO mode). The subnet must have the appropriate delegation for the chosen `agent_compute_type`."
}

variable "azure_existing_private_endpoints_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for private endpoints (BYO mode)."
}

variable "azure_existing_virtual_network_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing virtual network (BYO mode). Must be set together with `azure_existing_agents_subnet_resource_id` and `azure_existing_private_endpoints_subnet_resource_id`. When set, the module will not create a virtual network or agents resource group."
}

variable "azure_subnets_and_sizes" {
  type = map(number)
  default = {
    agents            = 27
    private_endpoints = 29
  }
  description = "The CIDR prefix sizes for subnets within the virtual network."

  validation {
    condition     = alltrue([for k in ["agents", "private_endpoints"] : contains(keys(var.azure_subnets_and_sizes), k)])
    error_message = "azure_subnets_and_sizes must contain entries for both 'agents' and 'private_endpoints'."
  }
}
