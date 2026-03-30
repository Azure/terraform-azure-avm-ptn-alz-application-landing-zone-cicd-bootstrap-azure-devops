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

variable "resource_name_environment" {
  type        = string
  description = "The name segment for the management environment (used for naming Azure infrastructure resources, not deployment environments)."
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
  description = "The short name segment for the location. When empty, auto-derived from the region geo code."
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
  description = "The sequence number to use for resource names."
  default     = 1
  validation {
    condition     = var.resource_name_sequence_start >= 1 && var.resource_name_sequence_start <= 999
    error_message = "The number must be between 1 and 999"
  }
}

variable "resource_name_templates" {
  type        = map(string)
  description = "A map of resource name templates. Each template supports placeholders: $${workload}, $${environment}, $${location}, $${location_short}, $${sequence}, $${uniqueness}."
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
