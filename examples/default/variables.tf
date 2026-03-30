variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  description = "The location/region where the resources will be created."
  default     = "uksouth"
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
