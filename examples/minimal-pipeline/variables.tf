variable "azuredevops_organization_name" {
  type        = string
  description = "The name of the Azure DevOps organization."
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "The location/region where the resources will be created."
}
