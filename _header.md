# Azure DevOps CI/CD Bootstrap for ALZ Application Landing Zones

This Azure Verified Module (AVM) pattern module bootstraps a complete, opinionated Azure DevOps CI/CD environment for an Azure Landing Zone (ALZ) **application landing zone**. It provisions the Azure DevOps platform surface, the supporting Azure resources for Terraform / Bicep state and self-hosted agent compute, and wires per-environment OIDC federated credentials so application teams can deploy from day one with no long-lived secrets.

## Features

### Azure DevOps platform

- **Project & repositories** — optionally creates a new Azure DevOps project (or attaches to an existing one) and seeds a main application repository plus an optional shared template repository for reusable pipeline templates.
- **Pipelines** — provisions CI / CD pipeline definitions wired to the repository, branch policies, and the agent pool. Auto-selects the pipeline folder based on `deployment_mode` (`terraform` / `bicep` / `other`) or accepts a custom path. Both the pipeline file names and template paths are user-overridable.
- **Environments & approvals** — creates one Azure DevOps environment per logical environment (e.g. `dev`, `prod`) with approvals / checks and pipeline authorizations.
- **Service connections** — creates one Workload Identity Federation service connection per environment, backed by a User Assigned Managed Identity with the appropriate RBAC over the target Azure subscription. No service principal secrets are issued.
- **Variable groups** — creates per-environment variable groups consumed by the CI / CD pipelines.
- **Security groups & permissions** — creates an Azure DevOps security group for the project administrators and wires pipeline / repository / environment permissions.
- **Repository seeding** — optionally seeds the application repository with an example Terraform or Bicep module (`example_module_path`).

### Self-hosted agents

- **Compute choice** — deploys self-hosted agents on either **Azure Container Instances** (`azure_container_instance`) or **Azure Container Apps** (`azure_container_app`). Defaults to ACI.
- **Authentication** — supports two agent authentication methods:
  - `uami` *(default, recommended)* — registers a User Assigned Managed Identity as an Azure DevOps service principal, grants it Administrator on the agent pool, and uses it for tokenless agent registration. **No PAT required.**
  - `pat` *(legacy)* — uses a Personal Access Token supplied via `var.agent_personal_access_token`.
- **Bring-your-own** — set `agent_existing_pool_name` to attach pipelines to an existing pool and skip all Azure compute provisioning, or set `agent_use_self_hosted = false` to use Microsoft-hosted agents.
- **Availability zones** — optionally spread compute across zones (`agent_compute_use_availability_zones`).

### Azure resources

- **Terraform state & plan storage** — when `deployment_mode = "terraform"`, provisions a hardened storage account (private endpoint, no public access) for Terraform remote state per environment, and, when `use_storage_account_for_plan = true` (the default), a dedicated `<env>-tfplan` container per environment for secure plan hand-off between the CD `plan` and `apply` stages.
- **Networking** — provisions a virtual network with dedicated subnets for agents and private endpoints, or accepts a pre-existing VNet / subnets in BYO mode.
- **Private DNS** — manages private DNS zones for private endpoints, with an opt-out (`azure_alz_platform_landing_zone_mode_enabled`) for ALZ platforms that manage DNS centrally via Azure Policy.
- **Identity** — creates the per-environment UAMIs used by the service connections, plus (when `agent_authentication_method = "uami"`) the UAMI used by the agent pool.
- **Resource groups** — creates dedicated resource groups for identity, state, agents, and networking (or reuses an existing VNet's resource group in BYO mode).

### Secure Terraform plan hand-off

- **Default-secure** — `use_storage_account_for_plan = true` by default. The CD `plan` stage uploads the binary plan to a per-environment Blob container (`<env>-tfplan`) instead of bundling it into the Azure Pipelines artifact; the `apply` stage downloads the exact same blob by build ID and deletes it after a successful apply.
- **Legacy fallback** — set `use_storage_account_for_plan = false` to revert to shipping the plan inside the Azure Pipelines build artifact. This is less secure (plan contents can include sensitive values and are retained per your organization's pipeline artifact retention policy) and is provided only for compatibility with self-managed/BYO template repos that haven't adopted the new templates.
- **Custom template repositories are not auto-secured** — if you set `azuredevops_existing_template_repository_name` or a custom pipeline template path, the module does not modify your pipeline YAML. You must adopt the upload/download/delete steps yourself for storage-backed hand-off to apply.
- **`show_plan_in_pipeline_logs`** — defaults to `false`. Enabling it prints the full plan to the pipeline log, visible to anyone with read access to the project/pipeline runs. Only enable if your organization has explicitly accepted that exposure.
- **`plan_storage_retention_days`** (default `7`) — a storage lifecycle policy rule deletes abandoned plan blobs, snapshots, and previous versions after this many days. This is a backstop only; successful applies delete their own plan blob immediately. Choose a value longer than the longest expected plan-to-apply approval wait; if a plan expires before approval, rerun the pipeline to generate a fresh plan.
- **Recoverability** — the plan container inherits the storage account's blob versioning/soft-delete settings, so an accidentally-deleted plan blob may still be recoverable within your soft-delete window.
- **Trusted-admin threat boundary** — this feature keeps plan contents out of Azure Pipelines artifact storage. It does not protect against an Azure user with Storage Blob Data Contributor/Owner-equivalent access to the storage account — the same trust boundary as Terraform remote state.
- **Stale/concurrent plans** — the `apply` stage always downloads the blob written by its own `plan` stage run (keyed by `$(Build.BuildId)`), never "the latest" blob, so a concurrent or superseded run cannot apply a stranger's plan.
- **Non-retroactive upgrade** — enabling this on an existing deployment only takes effect for the next `plan`/`apply` cycle; it does not migrate plans already in flight.
- **Upgrading an existing storage account** — `storage_management_policy_rule` replaces the account's *entire* lifecycle policy, not just this module's rules. If you already manage that storage account's lifecycle policy outside this module, applying this upgrade will silently overwrite those rules. Before upgrading, check existing rules with `az storage account management-policy show` and fold them into your Terraform config first.

## Authentication required to use the module

The module talks to two control planes: **Azure Resource Manager** and **Azure DevOps**. Configure provider authentication via environment variables — the module itself does not accept any provider credentials as input variables.

### Azure (`azurerm`, `azapi`) provider

Recommended: **OIDC federation** via `ARM_USE_OIDC=true` plus `ARM_TENANT_ID`, `ARM_CLIENT_ID`, `ARM_SUBSCRIPTION_ID`, and the OIDC token vars (`ARM_OIDC_REQUEST_TOKEN` / `ARM_OIDC_REQUEST_URL` in GitHub Actions, or equivalents in Azure DevOps). Service principal secret (`ARM_CLIENT_SECRET`) and `az login` are also supported.

The identity must hold **Owner** on the target subscription (or sufficient Contributor + User Access Administrator) because the module assigns RBAC to the per-environment UAMIs.

### Azure DevOps (`azuredevops`) provider

Recommended: **OIDC** via `AZDO_USE_OIDC=true` reusing the same `ARM_*` OIDC variables, plus `AZDO_ORG_SERVICE_URL=https://dev.azure.com/<org>`. A PAT (`AZDO_PERSONAL_ACCESS_TOKEN`) is also supported for backwards compatibility but is **not** required by this module.

The identity must be a **Project Collection Administrator** in the target Azure DevOps organization (or hold equivalent permissions to create projects, repositories, agent pools, service connections, environments, variable groups, security role assignments, and to add service principals to the organization).

### Legacy PAT (optional)

The only remaining token *input variable* is `var.agent_personal_access_token`, which is **only consumed when `var.agent_authentication_method = "pat"`** to register the self-hosted agents. With the default UAMI authentication method this variable can be left `null`.
