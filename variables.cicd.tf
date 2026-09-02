variable "azuredevops_create_main_repository" {
  type        = bool
  default     = true
  description = "Whether to create and manage the main repository and repository-scoped CI/CD resources."
}

variable "azuredevops_create_project" {
  type        = bool
  default     = true
  description = "Whether to create a new Azure DevOps project or use an existing one."
}

variable "azuredevops_create_template_repository" {
  type        = bool
  default     = true
  description = "Whether to create a template repository for CI/CD pipeline templates. Set to false if you don't need a template repository."
}

variable "azuredevops_existing_template_repository_name" {
  type        = string
  default     = null
  description = "The name of a pre-existing template repository containing CI/CD pipeline templates (BYO mode). When set, the module will not create a template repository or push template files."
}

variable "azuredevops_pipeline_folder_path" {
  type        = string
  default     = null
  description = "The absolute path to the folder containing pipeline YAML files. When null, auto-selects based on `deployment_mode` (e.g. 'pipelines/terraform' or 'pipelines/bicep'). Set to a custom path to use your own pipeline templates."
}

variable "azuredevops_pipelines" {
  type = map(object({
    main_file     = string
    template_path = string
  }))
  default     = null
  description = <<DESCRIPTION
A map of pipelines to create in the main repository. Each key is the pipeline name, and the value specifies:
- `main_file` - The source YAML file name within the pipeline folder's main/ directory.
- `template_path` - The path to the template within the template repository.
When null, defaults based on deployment_mode:
  terraform: { ci = { main_file = "ci.yaml", template_path = "ci-template.yaml" }, cd = { main_file = "cd.yaml", template_path = "cd-template.yaml" } }
  bicep: same structure
DESCRIPTION
}

variable "azuredevops_project_name" {
  type        = string
  default     = null
  description = "The name of the existing Azure DevOps project. Required if `create_project` is false."
}

variable "bicep_deployments" {
  type = list(object({
    name                = string
    template_file       = string
    parameters_file     = optional(string)
    scope               = optional(string, "group")
    resource_group      = optional(string)
    location            = optional(string)
    management_group_id = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
A list of Bicep deployment stack configurations. Each deployment specifies a template file, optional parameters file, and scope.
- `name` - (Required) The name of the deployment stack.
- `template_file` - (Required) The relative path to the Bicep template file.
- `parameters_file` - (Optional) The relative path to the parameters file.
- `scope` - (Optional) The deployment scope: 'group' (resource group), 'sub' (subscription), or 'mg' (management group). Defaults to 'group'.
- `resource_group` - (Optional) The resource group name. Required when scope is 'group'.
- `location` - (Optional) The deployment location. Required when scope is 'sub' or 'mg'.
- `management_group_id` - (Optional) The management group ID. Required when scope is 'mg'.
DESCRIPTION
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "The deployment mode for the module. Possible values are 'terraform', 'bicep', or 'other'. Only 'terraform' mode creates the storage account for Terraform state."

  validation {
    condition     = contains(["terraform", "bicep", "other"], var.deployment_mode)
    error_message = "deployment_mode must be 'terraform', 'bicep', or 'other'."
  }
}

variable "example_module_path" {
  type        = string
  default     = null
  description = "The absolute path to the example module to seed into the created repository."
}

variable "plan_storage_retention_days" {
  type        = number
  default     = 7
  description = "The number of days after which abandoned Terraform plan base blobs, snapshots, and previous versions are eligible for lifecycle deletion."

  validation {
    condition     = var.plan_storage_retention_days > 0 && floor(var.plan_storage_retention_days) == var.plan_storage_retention_days
    error_message = "plan_storage_retention_days must be a positive whole number."
  }
}

variable "show_plan_in_pipeline_logs" {
  type        = bool
  default     = false
  description = "Whether to print the full Terraform plan in pipeline logs. Enabling this can expose sensitive values."
}

variable "use_storage_account_for_plan" {
  type        = bool
  default     = true
  description = "Whether to use the Terraform state Storage Account for secure plan hand-off. Set to false to use the legacy CI/CD artifact hand-off."
}
