# Multi-environment Infrastructure as Code CI/CD templates

This repository is a collection of GitHub Actions useful for deploying Terraform using OIDC authentication.

It supports **multi-environment** solutions (i.e. those that need to deploy similar code to dev, test, prod, etc), with optional support for commonly required checks such as linting and code security static analysis enabled by default.

Azure Blob Storage is used for state and plan artifacts, to provide stronger RBAC than is available via GitHub packages.

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
      destroyResources: ${{ inputs.destroyResources == true || inputs.terraform_action == 'destroy' }}
      enable_infracost: true  # Optional: Enable cost estimation (requires INFRACOST_API_KEY secret)
    secrets: inherit

```

## Manual setup of of GitHub

If you'd prefer to configure GitHub manually, the following are required in the calling workflow:

1. **Create Environments:** Navigate to `Settings` -> `Environments`, create two for each target environment:
    - `<env_name>-iac-plan` (e.g., `dev-iac-plan`)
    - `<env_name>-iac-apply` (e.g., `dev-iac-apply`)

1. **Add Required Secrets:** Add the following **secrets** to **both** the `-plan` and `-apply` environments you just created:
    - `ARM_CLIENT_ID`: Client ID for the User Assigned Managed Identity used for deployment.
    - `ARM_SUBSCRIPTION_ID`: Target Azure Subscription ID for resource deployment.
    - `ARM_TENANT_ID`: Azure Tenant ID.

1. For Terraform only, create the following (also in both plan and apply environments):
    - `TF_STATE_RESOURCE_GROUP_NAME`: Resource group name containing the Terraform state storage account.
    - `TF_STATE_STORAGE_ACCOUNT_NAME`: Storage account name for Terraform state.

## Recommendation: Add Protection Rules

To prevent accidental deployments, configure protection rules on your `-apply` environments:

1. Go to Repository `Settings` -> `Environments` -> `<env_name>-iac-apply`.
1. Under **Deployment protection rules**, enable **Required reviewers**.
1. Configure reviewers (users or teams) who must approve deployments to this environment.
1. Save the protection rules.

This process is completed by Az-Bootstrap.

## Optional Variables

You can add these optional **secrets** to your environments (`-plan` and `-apply`) to customize behavior:

| Secret Name | Description | Default |
| :---------- | :---------- | :------ |
| `TF_STATE_SUBSCRIPTION_ID`      | Subscription ID for the Terraform state storage, only required if it is not the same as the deployment subscription account.   | `ARM_SUBSCRIPTION_ID` |
| `TF_STATE_STORAGE_CONTAINER_NAME` | Container name within the state storage account. | `tfstate` |
| `ARTIFACT_STORAGE_CONTAINER_NAME` | Container name for storing the Terraform plan artifact. | `tfartifact` |

You can pass additional environment variables to Terraform at runtime (via TF_VAR_), using this:

| Variable Name | Description | Default |
| :------------ | :---------- | :------ |
| `EXTRA_TF_VARS`           | Comma-separated `key=value` pairs passed as additional `-var` arguments to Terraform (e.g., `containertag=<SHA>,subid=<GUID>`)  This should be used sparingly, only for variables that need to be computed by previous steps. | (none) |

### Optional Secrets

| Secret Name | Description | Required for |
| :---------- | :---------- | :----------- |
| `INFRACOST_API_KEY` | API key for [Infracost](https://www.infracost.io/) cost estimation. Sign up for free at infracost.io to get your API key. | Cost estimation feature |

It is possible to specify a list of resource firewalls to unlock during the pipeline run, however we recommend using self-hosted or managed runners instead of this feature:

| Variable Name | Description | Default |
| :------------ | :---------- | :------ |
| `EXTRA_FIREWALL_UNLOCKS`  | Comma-separated list of additional `storageaccountname` or `keyvaultname` resources whose firewalls should be temporarily opened. | (none) |

## Cost Estimation with Infracost

This template includes optional support for [Infracost](https://www.infracost.io/), which provides cost estimates for your Terraform infrastructure changes. When enabled, cost estimates are automatically included in the plan summary posted to pull requests.

### Setting up Infracost

1. **Sign up for Infracost:** Create a free account at [infracost.io](https://www.infracost.io/) to get your API key.
1. **Add the API key:** Add `INFRACOST_API_KEY` as a **Secret** in your repository or environment settings.
1. **Enable in workflow:** Set `enable_infracost: true` in your workflow file (see example above).

### Features

- **Cost Diff:** Shows the monthly cost difference between current and planned infrastructure
- **PR Integration:** Cost estimates are automatically posted to pull request comments alongside the plan summary
- **Optional:** The feature is disabled by default and must be explicitly enabled

### Limitations

- Requires network access to Infracost's pricing API
- Cost estimates are approximations and may not include all Azure pricing factors
- Some Terraform resources may not be supported by Infracost

## Using Templates Across Repositories

To use these templates from another **private** repository within the same organization:

1. **Enable Access:** In *this* template repository (`github-azure-iac-templates`), go to `Settings` -> `Actions` -> `General`. Under **Access**, ensure "Accessible from repositories in the `<your_org_name>` organization" is selected.
1. **Update `uses` Path:** In the calling workflow of the *other* repository, update the `uses:` path to the full path of this template repository, **pinning to a specific version tag (recommended)**:

```yaml
  # Replace 'your-org-name' and use a real tag
  uses: your-org-name/github-azure-iac-templates/.github/workflows/terraform-deploy-template.yml@v1.0
```

*(Reference: [Managing access for Actions in an organization](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#managing-access-for-a-private-repository-in-an-organization))*
