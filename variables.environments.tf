variable "approvers" {
  type        = map(string)
  default     = {}
  description = "A map of approvers for environment approvals. The key is the approver name and the value is the user principal name."
}

variable "azuredevops_existing_approvers_group_origin_id" {
  type        = string
  default     = null
  description = "The origin ID of a pre-existing Azure DevOps group to use for approvals (BYO mode). When set, the module will not create an approval group or look up approver users."
}

variable "environments" {
  type = map(object({
    display_order         = number
    display_name          = string
    has_approval          = optional(bool, false)
    dependent_environment = optional(string, "")
    scope                 = optional(string, "resource_group")
    subscription_id       = optional(string)
    resource_id           = optional(string)
    resource_group_name   = optional(string)
    resource_group_create = optional(bool, true)
    identities = optional(object({
      read = optional(object({
        enabled               = optional(bool, true)
        name                  = optional(string)
        allowed_template_keys = optional(list(string))
        role_assignments = optional(map(object({
          role_definition_id_or_name = string
        })), { default = { role_definition_id_or_name = "Reader" } })
      }), {})
      write = optional(object({
        enabled               = optional(bool, true)
        name                  = optional(string)
        allowed_template_keys = optional(list(string))
        role_assignments = optional(map(object({
          role_definition_id_or_name = string
        })), { default = { role_definition_id_or_name = "Contributor" } })
      }), {})
    }), {})
  }))
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
  description = <<DESCRIPTION
A map of environments to create. Each environment has the following properties:
- `display_order` - (Required) The order to display the environment.
- `display_name` - (Required) The display name of the environment.
- `has_approval` - (Optional) Whether the environment requires approval. Defaults to `false`.
- `dependent_environment` - (Optional) The environment that this environment depends on.
- `scope` - (Optional) The deployment scope: 'resource_group', 'subscription', or 'management_group'. Defaults to 'resource_group'.
- `subscription_id` - (Optional) The subscription ID for the environment. Defaults to the current subscription.
- `resource_id` - (Optional) The resource ID of the target scope.
- `resource_group_name` - (Optional) Explicit resource group name. When null, generated from `resource_group_env_name` template in `resource_name_templates`.
- `resource_group_create` - (Optional) Whether to create a resource group. Only used when scope is 'resource_group' and resource_id is not set.
- `identities` - (Optional) An object with `read` and `write` identity configurations. Each has:
  - `enabled` - (Optional) Whether to create this identity. Defaults to `true`.
  - `name` - (Optional) Explicit identity name. When null, generated from `identity_read_name` or `identity_write_name` template in `resource_name_templates`.
  - `allowed_template_keys` - (Optional) Pipeline keys this identity is allowed to use for service connection checks. When null, read defaults to ['ci', 'cd'], write defaults to ['cd'].
  - `role_assignments` - (Optional) A map of role assignments. Each value has `role_definition_id_or_name`. Read defaults to Reader, write defaults to Contributor.
DESCRIPTION

  validation {
    condition     = alltrue([for k, v in var.environments : contains(["resource_group", "subscription", "management_group"], v.scope)])
    error_message = "Each environment scope must be 'resource_group', 'subscription', or 'management_group'."
  }
  validation {
    condition     = alltrue([for k, v in var.environments : v.identities.read.enabled || v.identities.write.enabled])
    error_message = "Each environment must have at least one identity enabled (read or write)."
  }
}
