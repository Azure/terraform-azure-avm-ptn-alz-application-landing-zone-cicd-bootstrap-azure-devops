variable "environments" {
  type = map(object({
    display_order                                = number
    display_name                                 = string
    has_approval                                 = optional(bool, false)
    dependent_environment                        = optional(string, "")
    scope                                        = optional(string, "resource_group")
    subscription_id                              = optional(string)
    resource_id                                  = optional(string)
    plan_role_definition_id_or_name              = optional(string, "Reader")
    apply_role_definition_id_or_name             = optional(string, "Contributor")
    resource_group_create                        = optional(bool, true)
    resource_group_name_template                 = optional(string, "rg-$${workload}-env-$${environment}-$${location}-$${sequence}")
    user_assigned_managed_identity_name_template = optional(string, "uami-$${workload}-$${environment}-$${type}-$${location}-$${sequence}")
  }))
  description = <<DESCRIPTION
A map of environments to create. Each environment has the following properties:
- `display_order` - (Required) The order to display the environment.
- `display_name` - (Required) The display name of the environment.
- `has_approval` - (Optional) Whether the environment requires approval. Defaults to `false`.
- `dependent_environment` - (Optional) The environment that this environment depends on.
- `scope` - (Optional) The deployment scope: 'resource_group', 'subscription', or 'management_group'. Defaults to 'resource_group'.
- `subscription_id` - (Optional) The subscription ID for the environment. Defaults to the current subscription.
- `resource_id` - (Optional) The resource ID of the target scope. For 'resource_group' scope with BYO RG, supply the resource group resource ID.
- `plan_role_definition_id_or_name` - (Optional) The role definition name or ID for the plan identity. Defaults to 'Reader'.
- `apply_role_definition_id_or_name` - (Optional) The role definition name or ID for the apply identity. Defaults to 'Contributor'.
- `resource_group_create` - (Optional) Whether to create a resource group. Only used when scope is 'resource_group' and resource_id is not set. Defaults to `true`.
- `resource_group_name_template` - (Optional) The template for the resource group name.
- `user_assigned_managed_identity_name_template` - (Optional) The template for the user assigned managed identity name.
DESCRIPTION
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
  validation {
    condition     = alltrue([for k, v in var.environments : contains(["resource_group", "subscription", "management_group"], v.scope)])
    error_message = "Each environment scope must be 'resource_group', 'subscription', or 'management_group'."
  }
}

variable "approvers" {
  type        = map(string)
  description = "A map of approvers for environment approvals. The key is the approver name and the value is the user principal name."
  default     = {}
}

variable "azuredevops_existing_approvers_group_origin_id" {
  type        = string
  default     = null
  description = "The origin ID of a pre-existing Azure DevOps group to use for approvals (BYO mode). When set, the module will not create an approval group or look up approver users."
}
