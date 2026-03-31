# Pre-test script to set authentication environment variables from secrets
# This script is run before terraform init/plan/apply in the test pipeline

# Set the Azure DevOps PAT from the repository secret for provider auth
# The AZDO_PERSONAL_ACCESS_TOKEN env var is used by both the azuredevops provider
# and the module when agent_authentication_method is "pat"
$env:AZDO_PERSONAL_ACCESS_TOKEN = $env:TF_VAR_azdo_personal_access_token

# Set the Azure DevOps org URL for provider auth
$env:AZDO_ORG_SERVICE_URL = $env:TF_VAR_azdo_org_service_url
