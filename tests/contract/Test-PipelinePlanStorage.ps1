#Requires -Version 7.4
<#
.SYNOPSIS
    Contract tests for the secure Terraform plan storage feature (issue #4174)
    as implemented in the Azure Pipelines templates.
.DESCRIPTION
    Statically inspects the pipeline template YAML (cd-template.yaml, ci-template.yaml,
    and the pipelines/terraform/templates/helpers/terraform-plan-*.yaml helpers) and
    proves, without needing Azure/Azure DevOps credentials or a live pipeline run, that
    the documented security contract for plan hand-off still holds in the template
    SOURCE:
      - the same computed container + an execution-bound (not attempt-bound) blob key
        is used across upload/download/delete
      - working directories only ever use $(Agent.TempDirectory)
      - the plan file is excluded from the (unencrypted) pipeline artifact when secure
        storage is enabled, and the legacy fallback still copies it in explicitly when
        secure storage is disabled
      - cleanup steps always run, even on failure
      - the two feature flags are always compared with exact 'true' strings
      - blob keys never embed the job attempt number
      - there is no blob listing, no "latest" blob convention, and no shared-key
        ("--account-key") auth anywhere
      - every blob operation uses --auth-mode login, the upload is verified by
        content-length comparison, and all three operations are bounded-retry loops
        (not unbounded)
      - no plan JSON ever ships in the published pipeline artifact
      - upload/download failures fail closed (throw); a post-success delete failure
        fails open (warns only, so a completed apply is never marked failed just
        because blob cleanup could not run)
    This is a static contract test, not an execution test: it proves the template TEXT
    matches the contract. It does not prove runtime behavior - that is the job of the
    runtime-evidence gate.
.PARAMETER RepoRoot
    Path to the module root. Defaults to two levels above this script
    (tests/contract/Test-PipelinePlanStorage.ps1 -> module root).
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'

$templatesDir = Join-Path $RepoRoot 'pipelines/terraform/templates'
$helpersDir = Join-Path $templatesDir 'helpers'

$paths = @{
    cd         = Join-Path $templatesDir 'cd-template.yaml'
    ci         = Join-Path $templatesDir 'ci-template.yaml'
    workspace  = Join-Path $helpersDir 'terraform-plan-workspace.yaml'
    upload     = Join-Path $helpersDir 'terraform-plan-upload.yaml'
    download   = Join-Path $helpersDir 'terraform-plan-download.yaml'
    delete     = Join-Path $helpersDir 'terraform-plan-delete.yaml'
    cleanup    = Join-Path $helpersDir 'terraform-plan-cleanup.yaml'
    plan       = Join-Path $helpersDir 'terraform-plan.yaml'
}

foreach ($p in $paths.GetEnumerator()) {
    if (-not (Test-Path -Path $p.Value)) {
        throw "Template not found: $($p.Value)"
    }
}

$raw = @{}
foreach ($p in $paths.GetEnumerator()) {
    $raw[$p.Key] = Get-Content -Raw -Path $p.Value
}

$script:failures = [System.Collections.Generic.List[string]]::new()
$script:passCount = 0

function Assert-Contract {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Description
    )
    if ($Condition) {
        Write-Host "  [PASS] $Description" -ForegroundColor Green
        $script:passCount++
    }
    else {
        Write-Host "  [FAIL] $Description" -ForegroundColor Red
        $script:failures.Add($Description)
    }
}

Write-Host "=== Secure plan storage contract tests (issue #4174, Azure DevOps) ===" -ForegroundColor Cyan

# --- 1. Same computed container + execution-bound key across upload/download/delete ---
Write-Host "`n-- Consistent, execution-bound blob addressing --"
$blobNamePattern = '\$blobName\s*=\s*"runs/\$env:ALZ_BUILD_ID/tfplan"'
foreach ($pair in @(
        @{ Name = 'upload'; Raw = $raw.upload },
        @{ Name = 'download'; Raw = $raw.download },
        @{ Name = 'delete'; Raw = $raw.delete }
    )) {
    Assert-Contract -Condition ($pair.Raw -match $blobNamePattern) `
        -Description "The $($pair.Name) step keys the blob as 'runs/`$(Build.BuildId)/tfplan' (execution-bound, not attempt-bound)."
    Assert-Contract -Condition ($pair.Raw -match 'ALZ_BUILD_ID:\s*\$\(Build\.BuildId\)') `
        -Description "The $($pair.Name) step maps ALZ_BUILD_ID from `$(Build.BuildId)."
    Assert-Contract -Condition ($pair.Raw -match '\$container\s*=\s*\$env:ALZ_PLAN_CONTAINER' -and $pair.Raw -match 'ALZ_PLAN_CONTAINER:\s*\$\(PLAN_STORAGE_CONTAINER_NAME\)') `
        -Description "The $($pair.Name) step reads the container name from the PLAN_STORAGE_CONTAINER_NAME pipeline variable."
    Assert-Contract -Condition ($pair.Raw -notmatch 'JobAttempt') `
        -Description "The $($pair.Name) step's blob key does not embed System.JobAttempt."
    Assert-Contract -Condition ($pair.Raw -match "condition:\s*and\(succeeded\(\),\s*eq\(variables\['USE_STORAGE_ACCOUNT_FOR_PLAN'\],\s*'true'\)\)") `
        -Description "The $($pair.Name) step only runs when USE_STORAGE_ACCOUNT_FOR_PLAN is exactly 'true'."
}

# --- 2. Agent.TempDirectory paths only ---
Write-Host "`n-- Working directories use Agent.TempDirectory only --"
Assert-Contract -Condition ($raw.workspace -match 'ALZ_AGENT_TEMP:\s*\$\(Agent\.TempDirectory\)') `
    -Description "The plan workspace step maps ALZ_AGENT_TEMP from `$(Agent.TempDirectory)."
Assert-Contract -Condition ($raw.workspace -match '\$planDir\s*=\s*Join-Path\s+\$env:ALZ_AGENT_TEMP') `
    -Description "The plan workspace step builds its working directory under `$env:ALZ_AGENT_TEMP."
Assert-Contract -Condition ($raw.workspace -match 'ALZ_JOB_ATTEMPT:\s*\$\(System\.JobAttempt\)' -and $raw.workspace -match '\$env:ALZ_JOB_ATTEMPT') `
    -Description "The plan workspace step includes the job attempt only in the *local* directory name, never the blob key."
Assert-Contract -Condition ($raw.workspace -match "task\.setvariable variable=alzPlanDir") `
    -Description "The plan workspace step publishes the resolved directory as the 'alzPlanDir' pipeline variable for later steps."

# --- 3 & 4. Plan excluded from secure artifact staging; legacy fallback copies it explicitly ---
Write-Host "`n-- Plan file staging matches the USE_STORAGE_ACCOUNT_FOR_PLAN flag --"
Assert-Contract -Condition ($raw.cd -match '!\*\*/tfplan\s*\r?\n\s*!\*\*/tfplan\.json') `
    -Description "Create Module Artifact excludes **/tfplan and **/tfplan.json from the staged content."
Assert-Contract -Condition ($raw.cd -match 'Add Plan to Module Artifact' -and $raw.cd -match "ne\(variables\['USE_STORAGE_ACCOUNT_FOR_PLAN'\],\s*'true'\)") `
    -Description "Copying tfplan into the module artifact staging directory is guarded by 'USE_STORAGE_ACCOUNT_FOR_PLAN != true'."
Assert-Contract -Condition ($raw.cd.IndexOf('Copy-Item') -ge 0 -and $raw.cd.IndexOf('Add Plan to Module Artifact') -ge 0 -and ($raw.cd.IndexOf('Add Plan to Module Artifact') - $raw.cd.IndexOf('Copy-Item')) -gt 0 -and ($raw.cd.IndexOf('Add Plan to Module Artifact') - $raw.cd.IndexOf('Copy-Item')) -lt 400) `
    -Description "The legacy (non-storage-account) fallback explicitly copies tfplan into the staging directory."
Assert-Contract -Condition (([regex]::Matches($raw.cd, "targetPath:\s*'\`$\(Build\.ArtifactStagingDirectory\)'")).Count -ge 1) `
    -Description "Publish Module Artifact publishes `$(Build.ArtifactStagingDirectory) using the correctly-spelled predefined variable (not the ArtifactsStagingDirectory typo)."
Assert-Contract -Condition ($raw.cd -notmatch 'ArtifactsStagingDirectory') `
    -Description "No step references the non-existent `$(Build.ArtifactsStagingDirectory) variable."

# --- 5. always() cleanup ---
Write-Host "`n-- Working directory cleanup always runs --"
Assert-Contract -Condition ($raw.cleanup -match 'condition:\s*always\(\)') `
    -Description "The Clean Up Plan Working Directory helper runs unconditionally (condition: always())."
Assert-Contract -Condition (([regex]::Matches($raw.cd, 'terraform-plan-cleanup\.yaml')).Count -ge 2) `
    -Description "cd-template.yaml invokes the cleanup helper in both the plan and apply jobs."
Assert-Contract -Condition (([regex]::Matches($raw.ci, 'terraform-plan-cleanup\.yaml')).Count -ge 1) `
    -Description "ci-template.yaml invokes the cleanup helper in the validate/plan job."

# --- 6. Exact 'true' string comparisons for both feature flags ---
Write-Host "`n-- Feature flags are compared as exact 'true' strings --"
$flagNames = @('USE_STORAGE_ACCOUNT_FOR_PLAN', 'SHOW_PLAN_IN_PIPELINE_LOGS')
foreach ($fileInfo in @(
        @{ Name = 'ci-template.yaml'; Raw = $raw.ci },
        @{ Name = 'cd-template.yaml'; Raw = $raw.cd },
        @{ Name = 'terraform-plan-upload.yaml'; Raw = $raw.upload },
        @{ Name = 'terraform-plan-download.yaml'; Raw = $raw.download },
        @{ Name = 'terraform-plan-delete.yaml'; Raw = $raw.delete }
    )) {
    foreach ($flag in $flagNames) {
        $comparisonLines = ($fileInfo.Raw -split "`n") | Where-Object { $_ -match [regex]::Escape($flag) -and $_ -match '(eq\(|ne\(|-eq |==)' }
        foreach ($line in $comparisonLines) {
            Assert-Contract -Condition ($line -match "'true'") `
                -Description "$($fileInfo.Name): comparison against $flag uses a quoted 'true' string ($($line.Trim()))."
        }
    }
}

# --- 7. No blob listing, no "latest" convention, no shared-key auth ---
Write-Host "`n-- No blob listing, no latest-blob convention, no shared-key auth --"
foreach ($pair in @(
        @{ Name = 'upload'; Raw = $raw.upload },
        @{ Name = 'download'; Raw = $raw.download },
        @{ Name = 'delete'; Raw = $raw.delete }
    )) {
    Assert-Contract -Condition ($pair.Raw -notmatch 'az storage blob list') `
        -Description "The $($pair.Name) step does not list blobs (it addresses an exact known key only)."
    Assert-Contract -Condition ($pair.Raw -notmatch '--account-key') `
        -Description "The $($pair.Name) step does not authenticate with a storage account shared key."
    Assert-Contract -Condition ($pair.Raw -notmatch '(?i)\blatest\b') `
        -Description "The $($pair.Name) step does not use a mutable 'latest' blob alias."
}

# --- 8. --auth-mode login + content validation + bounded retries ---
Write-Host "`n-- Auth mode, content validation, bounded retries --"
foreach ($pair in @(
        @{ Name = 'upload'; Raw = $raw.upload; Command = 'az storage blob upload' },
        @{ Name = 'download'; Raw = $raw.download; Command = 'az storage blob download' },
        @{ Name = 'delete'; Raw = $raw.delete; Command = 'az storage blob delete' }
    )) {
    Assert-Contract -Condition ($pair.Raw -match [regex]::Escape($pair.Command)) `
        -Description "The $($pair.Name) step calls '$($pair.Command)'."
    Assert-Contract -Condition ($pair.Raw -match '--auth-mode login') `
        -Description "The $($pair.Name) step authenticates with --auth-mode login (Microsoft Entra ID, not a shared key)."
    Assert-Contract -Condition ($pair.Raw -match '\$maxAttempts\s*=\s*\d+' -and $pair.Raw -match 'for\s*\(\$attempt\s*=\s*1;\s*\$attempt\s*-le\s*\$maxAttempts') `
        -Description "The $($pair.Name) step retries a bounded number of times (not an unbounded loop)."
}
Assert-Contract -Condition ($raw.upload -match 'az storage blob show' -and $raw.upload -match '--query properties\.contentLength') `
    -Description "The upload step verifies the uploaded blob's content length against the local plan file."
Assert-Contract -Condition ($raw.download -match '\(Get-Item\s+-Path\s+\$planFile\)\.Length\s+-eq\s+0') `
    -Description "The download step rejects an empty downloaded plan file."

# --- 9. No plan JSON ships in the published artifact ---
Write-Host "`n-- No plan JSON ships in the published pipeline artifact --"
Assert-Contract -Condition ($raw.cd -notmatch "targetPath:\s*'tfplan\.json'" -and $raw.cd -notmatch "artifact:\s*'plan_") `
    -Description "cd-template.yaml never publishes a standalone plan/tfplan.json artifact."
Assert-Contract -Condition ($raw.ci -notmatch 'PublishPipelineArtifact') `
    -Description "ci-template.yaml no longer publishes the plan JSON as a pipeline artifact (Terraform Plan Summary only prints counts to the log)."
Assert-Contract -Condition ($raw.ci -match [regex]::Escape('show -json "$(alzPlanDir)/tfplan" > "$(alzPlanDir)/tfplan.json"')) `
    -Description "ci-template.yaml's Terraform Plan Summary writes tfplan.json under the agent-temp plan directory, never under the sources/artifact directory."

# --- 10. Fail-closed upload/download, fail-open post-success delete ---
Write-Host "`n-- Fail-closed upload/download; fail-open (warn-only) cleanup delete --"
Assert-Contract -Condition ($raw.upload -match 'if\s*\(-not\s*\$uploaded\)\s*\{\s*\r?\n\s*throw') `
    -Description "Upload failure throws (fails the pipeline closed) rather than silently continuing."
Assert-Contract -Condition ($raw.download -match 'if\s*\(-not\s*\$downloaded\)\s*\{\s*\r?\n\s*throw') `
    -Description "Download failure throws (fails the pipeline closed) rather than silently continuing."
Assert-Contract -Condition ($raw.download -match 'Test-Path[^\r\n]*\$planFile\)[\s\S]{0,40}-or[\s\S]{0,80}-eq 0\)\s*\{\s*\r?\n\s*throw') `
    -Description "A missing or empty downloaded plan file throws (fails the pipeline closed)."
Assert-Contract -Condition ($raw.delete -match 'if\s*\(-not\s*\$deleted\)\s*\{\s*\r?\n\s*Write-Warning') `
    -Description "Post-apply delete failure only warns (a completed apply is not marked failed just because blob cleanup could not run)."
$applyIdx = $raw.cd.IndexOf('terraform-apply.yaml')
$deleteIdx = $raw.cd.IndexOf('terraform-plan-delete.yaml')
Assert-Contract -Condition ($applyIdx -ge 0 -and $deleteIdx -gt $applyIdx) `
    -Description "cd-template.yaml invokes terraform-plan-delete.yaml only after terraform-apply.yaml, i.e. only on the happy path (a failed apply stops the job before delete runs)."

# --- 11. Failed-plan output is redacted unless explicitly enabled ---
Write-Host "`n-- Failed-plan log output respects SHOW_PLAN_IN_PIPELINE_LOGS --"
$failureBlockMatch = [regex]::Match($raw.plan, '(?s)\}\s*elseif\s*\(\$planExitCode\s*-ne\s*0\)\s*\{.*?\}\s*else\s*\{.*?\}')
Assert-Contract -Condition $failureBlockMatch.Success `
    -Description "terraform-plan.yaml: the three-way branch (shown / failed-redacted / succeeded-redacted) was found for inspection."
Assert-Contract -Condition ($raw.plan -match 'Get-Content -Path \$planLogFile \| Write-Host') `
    -Description "terraform-plan.yaml: the full captured plan log is only ever dumped inside the `$showPlanInPipelineLogs branch."
Assert-Contract -Condition ($raw.plan -match 'diagnosticBlocks') `
    -Description "terraform-plan.yaml: when the flag is not true and the plan failed, only Terraform's own diagnostic block(s) are extracted from the log."
if ($failureBlockMatch.Success) {
    Assert-Contract -Condition ($failureBlockMatch.Value -notmatch 'Get-Content -Path \$planLogFile \| Write-Host') `
        -Description "terraform-plan.yaml: the redacted failure branch never falls back to dumping the entire raw captured log."
}
Assert-Contract -Condition ($raw.plan -match 'Remove-Item -Path \$planLogFile -Force -ErrorAction SilentlyContinue') `
    -Description "terraform-plan.yaml: the captured plan log file itself is removed after being processed, so it cannot leak via a later artifact-staging step."

# --- Summary ---
Write-Host "`n=== Summary: $($script:passCount) passed, $($script:failures.Count) failed ===" -ForegroundColor Cyan
if ($script:failures.Count -gt 0) {
    Write-Host "`nFailed checks:" -ForegroundColor Red
    foreach ($f in $script:failures) {
        Write-Host "  - $f" -ForegroundColor Red
    }
    exit 1
}
exit 0
