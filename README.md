# Github Terraform CI/CD templates

This repository is a collection of GitHub Actions useful for deploying Terraform.

## Getting started

Set up required variables in the calling repository.

- Repository settings -> Environments - New environment:
  - Plan : `<env name>_plan`
  - Apply : `<env name>_apply`

Set Protection rule on the Apply environment in the calling repository.

- Repository settings -> Environments -> `<env name>_apply` -> Deployment protection rules
  - turn on required reviewers and configure reviewers and self-reviewer restriction
  - select save protection rules

Add the following environment variables to both plan and apply environments:

- Repository settings -> Environments
  - select environment and scroll down to variables
    - AZURE_CLIENT_ID - Client ID for the User Assigned Managed Identity
    - AZURE_SUBSCRIPTION_ID - Subscription ID for the deployment
    - AZURE_TENANT_ID - Tenant id for the deployment
    - TF_STATE_RESOURCE_GROUP - Resource group for the terraform state storage account
    - TF_STATE_BLOB_ACCOUNT - Terraform state storage account name

    - TF_SUBSCRIPTION_ID - (optional) Subscription ID for the terraform state storage account. If empty will default to AZURE_SUBSCRIPTION_ID

    - TF_STATE_BLOB_CONTAINER- (optional) Terraform state storage container name. Will default to tfstate.
    - EXTRA_FIREWALL_UNLOCKS - (optional) Specifies extra key vaults and storage accounts to unlock
    - EXTRA_TF_VARS - (optional) Specifies extra variables for the terraform deployment. Comma separated key=value pairs.
    - ARTIFACT_BLOB_CONTAINER - (optional) Specifies the container in the Terraform state storage account to store the build artifact. Defaults to tfartifact

The example below can be used from the calling repository

```yaml
name: Terraform Deployment

on:
  workflow_dispatch:
    inputs:
      terraform_action:
        description: 'Terraform Action'
        default: apply
        type: choice
        options:
          - apply
          - destroy
          - plan
      target_environment:
        description: 'Select environment'
        required: true
        type: choice
        default: dev
        options:  ## options should match required environments
          - dev
          - test
          - prod
      destroyResources:
        type: boolean
        default: false

run-name: Terraform ${{ inputs.terraform_action }} ( ${{ inputs.target_environment }}) by @${{ github.actor }} for ${{ github.workflow }}

permissions:
  id-token: write
  contents: read

jobs:
  call-terraform-deploy:
    name: "Run terraform ${{ inputs.terraform_action }} for ${{ inputs.target_environment }}"
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-deploy-template.yml@main
    with:
      terraform_action: ${{ inputs.terraform_action }}
      plan_target_environment: "${{ inputs.target_environment }}_plan"
      apply_target_environment: "${{ inputs.target_environment }}_apply"
      tfvars_file: "./environments/${{ inputs.target_environment }}.terraform.tfvars"
      tfstate_file: "${{ inputs.target_environment }}.tfstate"
      destroyResources: ${{ inputs.destroyResources == true || inputs.terraform_action == 'destroy' }}
```

## Share these templates with other repos

To allow other private repositories in the org to use these templates:

- Under the repository, click Settings.
- In the left sidebar, click Actions, then click General.
- Under Access, "Accessible from repositories in the __ organization"

ref: <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#managing-access-for-a-private-repository-in-an-organization>
