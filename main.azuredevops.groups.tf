resource "azuredevops_group" "this" {
  count        = local.create_approval_group ? 1 : 0
  scope        = local.azure_devops_project_id
  display_name = local.resource_names.group_name
  description  = "Approvers for the Terraform Apply"
}

data "azuredevops_users" "this" {
  for_each       = local.create_approval_group ? var.approvers : {}
  principal_name = each.value
  lifecycle {
    postcondition {
      condition     = length(self.users) > 0
      error_message = "No user account found for ${each.value}, check you have entered a valid user principal name..."
    }
  }
}

locals {
  approvers = toset(flatten([for approver in data.azuredevops_users.this :
    [for user in approver.users : user.descriptor]
  ]))
}

resource "azuredevops_group_membership" "this" {
  count   = local.create_approval_group ? 1 : 0
  group   = azuredevops_group.this[0].descriptor
  members = local.approvers
}
