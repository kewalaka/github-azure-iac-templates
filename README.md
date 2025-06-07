# Multi-environment Infrastructure as Code CI/CD templates

This repository is a collection of GitHub Actions useful for deploying Terraform using OIDC authentication.

It supports **multi-environment** solutions (i.e. those that need to deploy similar code to dev, test, prod, etc), with optional support for commonly required checks such as linting and code security static analysis enabled by default.

For Bicep, Azure deployment stacks are used across resource group, subscription, and management group scopes.

For Terraform, Azure Blob Storage is used for state and plan artifacts, to provide stronger RBAC than is available via GitHub packages.

## Quick Start

The recommended way to get started with these templates is to use [Az-Bootstrap](https://github.com/kewalaka/az-bootstrap).

Az-Bootstrap needs a template repository, you can optionally use this one: <https://github.com/kewalaka/terraform-azure-starter-template>

This will create:

- Azure resources (resource groups, managed identities, storage account for state file)
- GitHub resources (environments, recommended branch protection & reviewers)

The template usage includes an example of calling the re-usable workflow, set up for a single `dev` environment.

## Usage

Create a workflow file (e.g., `.github/workflows/deploy.yml`) in your repository with the following content. This example uses `workflow_dispatch` for manual triggering:

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
        description: 'Select target environment'
        required: true
        type: choice
        default: dev
        options:  # options should match your configured environments (e.g., dev, test, prod)
          - dev
          - test
          - prod
      destroy_resources:
        description: 'Actually destroy resources?'
        type: boolean
        default: false

run-name: Terraform ${{ inputs.terraform_action }} (${{ inputs.target_environment }}) by @${{ github.actor }}

permissions:
  id-token: write # Required for OIDC authentication
  contents: read  # Required to checkout code
  pull-requests: write # Terraform Plan summaries can be written to PRs as comments
  security-events: write # Allow upload of sarif outputs

jobs:
  call-terraform-deploy:
    name: "Run terraform ${{ inputs.terraform_action }} for ${{ inputs.target_environment }}"
    uses: kewalaka/github-azure-iac-templates/.github/actions/.github/workflows/terraform-deploy-template.yml@v1.0
    with:
      terraform_action: ${{ inputs.terraform_action }}
      environment_name_plan: "${{ inputs.target_environment }}_plan"
      environment_name_apply: "${{ inputs.target_environment }}_apply"
      tfvars_file: "./environments/${{ inputs.target_environment }}.terraform.tfvars"
      destroy_resources: ${{ inputs.destroy_resources == true || inputs.terraform_action == 'destroy' }}
    secrets: inherit

```

### Example Usage - Bicep Deployment Stacks

Create a workflow file (e.g., `.github/workflows/deploy-bicep.yml`) in your repository with the following content. This example uses `workflow_dispatch` for manual triggering:

```yaml
name: Bicep Deployment Stacks

on:
  workflow_dispatch:
    inputs:
      bicep_action:
        description: 'Bicep Action'
        default: deploy
        type: choice
        options:
          - deploy
          - plan
      target_environment:
        description: 'Select environment'
        required: true
        type: choice
        default: dev
        options:  # options should match your configured environments (e.g., dev, test, prod)
          - dev
          - test
          - prod
      deployment_scope:
        description: 'Deployment scope'
        required: true
        type: choice
        default: resourceGroup
        options:
          - resourceGroup
          - subscription
          - managementGroup

run-name: Bicep ${{ inputs.bicep_action }} (${{ inputs.target_environment }}) by @${{ github.actor }}

permissions:
  id-token: write # Required for OIDC authentication
  contents: read  # Required to checkout code
  pull-requests: write # Required for PR commenting during plan

jobs:
  call-bicep-deploy:
    name: "Run bicep ${{ inputs.bicep_action }} for ${{ inputs.target_environment }}"
    uses: kewalaka/github-azure-iac-templates/.github/workflows/bicep-deploy-template.yml@v1.0
    with:
      bicep_action: ${{ inputs.bicep_action }}
      plan_target_environment: "${{ inputs.target_environment }}_plan"
      apply_target_environment: "${{ inputs.target_environment }}_apply"
      deployment_scope: ${{ inputs.deployment_scope }}
      deployment_stack_name: "${{ inputs.target_environment }}-stack"  # Optional: auto-generated if not provided
      bicep_root_path: "./iac"
      parameters_file_path: "parameters/${{ inputs.target_environment }}.parameters.json"
      resource_group_name: "${{ inputs.deployment_scope == 'resourceGroup' && format('rg-{0}', inputs.target_environment) || '' }}"
      management_group_id: "${{ inputs.deployment_scope == 'managementGroup' && 'your-mg-id' || '' }}"
      location: "eastus"
      action_on_unmanage: "detachAll"  # Options: detachAll, deleteAll
      deny_settings_mode: "none"       # Options: none, denyDelete, denyWriteAndDelete
    secrets: inherit

```

## Recommendation: Add Protection Rules

To prevent accidental deployments, configure protection rules on your `-apply` environments:

1. Go to Repository `Settings` -> `Environments` -> `<env_name>-iac-apply`.
1. Under **Deployment protection rules**, enable **Required reviewers**.
1. Configure reviewers (users or teams) who must approve deployments to this environment.
1. Save the protection rules.

This process is completed by Az-Bootstrap.

## Optional Variables

### Terraform Variables

You can add these optional **secrets** to your environments (`_plan` and `_apply`) to customize Terraform behavior:

| Secret Name | Description | Default |
| :---------- | :---------- | :------ |
| `TF_STATE_SUBSCRIPTION_ID`      | Subscription ID for the Terraform state storage, only required if it is not the same as the deployment subscription account.   | `ARM_SUBSCRIPTION_ID` |
| `TF_STATE_STORAGE_CONTAINER_NAME` | Container name within the state storage account. | `tfstate` |
| `ARTIFACT_STORAGE_CONTAINER_NAME` | Container name for storing the Terraform plan artifact. | `tfartifact` |

You can pass additional environment variables to Terraform at runtime (via TF_VAR_), using this:

| Variable Name | Description | Default |
| :------------ | :---------- | :------ |
| `EXTRA_TF_VARS`           | Comma-separated `key=value` pairs passed as additional `-var` arguments to Terraform (e.g., `containertag=<SHA>,subid=<GUID>`)  This should be used sparingly, only for variables that need to be computed by previous steps. | (none) |

### Bicep Variables

For Bicep deployment stacks, you can customize stack behavior using the following parameters:

| Parameter Name | Description | Default | Options |
| :------------ | :---------- | :------ | :------ |
| `deployment_stack_name` | Name for the deployment stack | Auto-generated from repository name | Any valid Azure resource name |
| `action_on_unmanage` | What happens to resources no longer managed by the stack | `detachAll` | `detachAll`, `deleteAll` |
| `deny_settings_mode` | Operations denied on stack-managed resources | `none` | `none`, `denyDelete`, `denyWriteAndDelete` |

**Note:** Stack names are automatically generated based on the calling repository name if not explicitly provided. The what-if functionality uses standard Azure deployment commands since stacks don't support what-if operations directly.

### Common Variables

It is possible to specify a list of resource firewalls to unlock during the pipeline run, however we recommend using self-hosted or managed runners instead of this feature:

| Variable Name | Description | Default |
| :------------ | :---------- | :------ |
| `EXTRA_FIREWALL_UNLOCKS`  | Comma-separated list of additional `storageaccountname` or `keyvaultname` resources whose firewalls should be temporarily opened. | (none) |

## Using Templates Across Repositories

To use these templates from another **private** repository within the same organization:

1. **Enable Access:** In *this* template repository (`github-azure-iac-templates`), go to `Settings` -> `Actions` -> `General`. Under **Access**, ensure "Accessible from repositories in the `<your_org_name>` organization" is selected.
1. **Update `uses` Path:** In the calling workflow of the *other* repository, update the `uses:` path to the full path of this template repository, **pinning to a specific version tag (recommended)**:

```yaml
  # Replace 'your-org-name' and use a real tag
  uses: your-org-name/github-azure-iac-templates/.github/workflows/terraform-deploy-template.yml@v1.0
```

*(Reference: [Managing access for Actions in an organization](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#managing-access-for-a-private-repository-in-an-organization))*
