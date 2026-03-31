variable "location" {
  type        = string
  description = "The location/region where the resources will be created."
  default     = "uksouth"
}

variable "azuredevops_organization_name" {
  type        = string
  description = "The name of the Azure DevOps organization."
}

variable "target_subscription_id" {
  type        = string
  default     = null
  description = "The subscription ID for the target environment. When null, uses the current subscription."
}
