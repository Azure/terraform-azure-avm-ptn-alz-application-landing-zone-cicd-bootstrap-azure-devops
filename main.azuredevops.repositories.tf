locals {
  default_branch = "refs/heads/main"
}

resource "azuredevops_git_repository" "this" {
  count          = local.create_main_repository ? 1 : 0
  depends_on     = [azuredevops_environment.this]
  project_id     = local.azure_devops_project_id
  name           = local.resource_names.repository_main_name
  default_branch = local.default_branch
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_git_repository" "template" {
  count          = local.create_main_repository && local.create_template_repository ? 1 : 0
  depends_on     = [azuredevops_environment.this]
  project_id     = local.azure_devops_project_id
  name           = local.resource_names.repository_template_name
  default_branch = local.default_branch
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_branch_policy_min_reviewers" "this" {
  count      = local.create_main_repository ? 1 : 0
  depends_on = [azuredevops_git_repository_file.this]
  project_id = local.azure_devops_project_id

  enabled  = local.has_approvers
  blocking = true

  settings {
    reviewer_count                         = 1
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    allow_completion_with_rejects_or_waits = false
    on_push_reset_approved_votes           = true

    scope {
      repository_id  = azuredevops_git_repository.this[0].id
      repository_ref = azuredevops_git_repository.this[0].default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_merge_types" "this" {
  count      = local.create_main_repository ? 1 : 0
  depends_on = [azuredevops_git_repository_file.this]
  project_id = local.azure_devops_project_id

  enabled  = true
  blocking = true

  settings {
    allow_squash                  = true
    allow_rebase_and_fast_forward = false
    allow_basic_no_fast_forward   = false
    allow_rebase_with_merge       = false

    scope {
      repository_id  = azuredevops_git_repository.this[0].id
      repository_ref = azuredevops_git_repository.this[0].default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_build_validation" "this" {
  count      = local.create_main_repository ? 1 : 0
  depends_on = [azuredevops_git_repository_file.this]
  project_id = local.azure_devops_project_id

  enabled  = true
  blocking = true

  settings {
    display_name        = "Terraform Validation"
    build_definition_id = azuredevops_build_definition.this["ci"].id
    valid_duration      = 720

    scope {
      repository_id  = azuredevops_git_repository.this[0].id
      repository_ref = azuredevops_git_repository.this[0].default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_min_reviewers" "template" {
  count      = local.create_main_repository && local.create_template_repository ? 1 : 0
  depends_on = [azuredevops_git_repository_file.template]
  project_id = local.azure_devops_project_id

  enabled  = local.has_approvers
  blocking = true

  settings {
    reviewer_count                         = 1
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    allow_completion_with_rejects_or_waits = false
    on_push_reset_approved_votes           = true

    scope {
      repository_id  = azuredevops_git_repository.template[0].id
      repository_ref = azuredevops_git_repository.template[0].default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_merge_types" "template" {
  count      = local.create_main_repository && local.create_template_repository ? 1 : 0
  depends_on = [azuredevops_git_repository_file.template]
  project_id = local.azure_devops_project_id

  enabled  = true
  blocking = true

  settings {
    allow_squash                  = true
    allow_rebase_and_fast_forward = false
    allow_basic_no_fast_forward   = false
    allow_rebase_with_merge       = false

    scope {
      repository_id  = azuredevops_git_repository.template[0].id
      repository_ref = azuredevops_git_repository.template[0].default_branch
      match_type     = "Exact"
    }
  }
}
