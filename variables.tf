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

variable "agent_personal_access_token" {
  type        = string
  default     = null
  description = "The personal access token for the Azure DevOps organization. Required for agent authentication when `agent_authentication_method` is 'pat'. Provider auth should be configured via the AZDO_PERSONAL_ACCESS_TOKEN environment variable."
  sensitive   = true

  validation {
    condition     = !(var.agent_use_self_hosted && var.agent_authentication_method == "pat") || var.agent_personal_access_token != null
    error_message = "agent_personal_access_token must be set when agent_use_self_hosted is true and agent_authentication_method is 'pat'."
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

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
