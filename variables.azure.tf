# --- Virtual Network ---

variable "azure_address_space" {
  type        = string
  description = "The virtual network address space."
  default     = "10.0.0.0/24"
}

variable "azure_subnets_and_sizes" {
  type        = map(number)
  description = "The CIDR prefix sizes for subnets within the virtual network."
  default = {
    agents            = 27
    private_endpoints = 29
  }
}

variable "azure_existing_virtual_network_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing virtual network (BYO mode). Must be set together with `existing_agents_subnet_resource_id` and `existing_private_endpoints_subnet_resource_id`. When set, the module will not create a virtual network or agents resource group."
}

variable "azure_existing_agents_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for agents (BYO mode). The subnet must have the appropriate delegation for the chosen `compute_type`."
}

variable "azure_existing_private_endpoints_subnet_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of a pre-existing subnet for private endpoints (BYO mode)."
}

# --- Self-Hosted Agents ---

variable "agent_use_self_hosted" {
  type        = bool
  description = "Whether to use self-hosted agents. When false, pipelines use Microsoft-hosted agents."
  default     = true
}

variable "agent_existing_pool_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing Azure DevOps agent pool (BYO mode). When set, the module will not create an agent pool or any Azure compute infrastructure. The provided pool name will be used in pipeline YAML files."
}

variable "agent_compute_type" {
  type        = string
  description = "The type of Azure compute to use for self-hosted agents. Must be either 'azure_container_app' or 'azure_container_instance'."
  default     = "azure_container_instance"
  validation {
    condition     = contains(["azure_container_app", "azure_container_instance"], var.agent_compute_type)
    error_message = "compute_type must be either 'azure_container_app' or 'azure_container_instance'."
  }
}

variable "agent_compute_use_availability_zones" {
  type        = bool
  default     = false
  description = "Use availability zones for the compute instances. This is off by default due to faults in various regions at time of authoring."
}

variable "agent_authentication_method" {
  type        = string
  default     = "uami"
  description = "The authentication method for self-hosted agents. Possible values are 'pat' or 'uami'. UAMI (User Assigned Managed Identity) does not require a PAT for agent authentication."
  validation {
    condition     = contains(["pat", "uami"], var.agent_authentication_method)
    error_message = "agent_authentication_method must be 'pat' or 'uami'."
  }
}

# --- Storage / Private Networking ---

variable "azure_alz_platform_landing_zone_mode_enabled" {
  type        = bool
  default     = false
  description = "When enabled, the module will not create private DNS zones and will not manage DNS zone groups for private endpoints. This is useful when the platform landing zone is managing DNS zones centrally via Azure Policy."
}
