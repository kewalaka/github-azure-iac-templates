# Multi-environment Infrastructure as Code CI/CD templates

This repository is a collection of GitHub Actions useful for deploying Terraform using OIDC authentication.

It supports **multi-environment** solutions (i.e. those that need to deploy similar code to dev, test, prod, etc), with optional support for commonly required checks such as linting and code security static analysis enabled by default.

Check the [Optional Features](#optional_features) section below to configure settings for:

- Terraform Lint
- Checkov infrastructure scanning (tfplan enriched)
- Additional TFVARs at run time
- Terraform backend options
- Automatic creation of Terraform backend
- Unlock private networking resource firewalls if not using runners

## Usage

Below are manual instructions for getting started.  If you're looking to automate this process, check out [Az-Bootstrap](https://github.com/kewalaka/az-bootstrap).

### GitHub repository settings

The following steps should be completed in the calling repository:

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

### GitHub workflow

Create a workflow file (e.g., `.github/workflows/deploy.yml`) in your repository to call the deploy template.

The example below uses `workflow_dispatch` for manual triggering:

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
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-deploy-template.yml@main
    with:
      terraform_action: ${{ inputs.terraform_action }}
      environment_name_plan: "${{ inputs.target_environment }}-iac-plan"
      environment_name_apply: "${{ inputs.target_environment }}-iac-apply"
      tfvars_file: "./environments/${{ inputs.target_environment }}.terraform.tfvars"      
      destroy_resources: ${{ inputs.destroy_resources == true || inputs.terraform_action == 'destroy' }}
    secrets: inherit

```

## Recommendation: Add Protection Rules

To prevent accidental deployments, configure protection rules on your `-apply` environments:

1. Go to Repository `Settings` -> `Environments` -> `<env_name>-iac-apply`.
1. Under **Deployment protection rules**, enable **Required reviewers**.
1. Configure reviewers (users or teams) who must approve deployments to this environment.
1. Save the protection rules.

Az-Bootstrap performs this step automatically by default.

<a id="optional_features"></a><!-- markdownlint-disable-line MD033 -->

## Optional Variables

The following section provides details of how to tune the configuration of the deployment templates.

### Root folder

The default folder for IaC is `./iac`.  This can be modified using `root_module_folder_relative_path`

### TFLint, validate and format linting

This is enabled by default, can be disabled using `enable_static_analysis_checks: false`

TFLint can further be configured in the calling repository by
placing a file `.tflint.hcl` in the IaC root.

Check out the actions [README.md](.github/actions/terraform-lint/README.md) for more details.

### Checkov (security scanning)

[Checkov](https://www.checkov.io/) is enabled by default, can be disabled using `enable_checkov: false`

Check out the actions [README.md](.github/actions/checkov-terraform/README.md) for more details.

### Automatic Terraform backend

If the pipeline principal has sufficient permissions, it is possible to make the Terraform backend automatically.  This action can also be used to check the backend is available.

This is disabled by default, can be enabled using `deploy_backend: true`

Check out the actions [README.md](.github/actions/terraform-backend/README.md) for more details.

### Terraform storage account configurable options

You can add these optional **secrets** to your environments (`-plan` and `-apply`) to customize behavior:

| Secret Name | Description | Default |
| :---------- | :---------- | :------ |
| `TF_STATE_SUBSCRIPTION_ID`      | Subscription ID for the Terraform state storage, only required if it is not the same as the deployment subscription account.   | `ARM_SUBSCRIPTION_ID` |
| `TF_STATE_STORAGE_CONTAINER_NAME` | Container name within the state storage account. | `tfstate` |
| `ARTIFACT_STORAGE_CONTAINER_NAME` | Container name for storing the Terraform plan artifact. | `tfartifact` |

### Additional TFVARS at runtime

These are supplied using TF_VAR_ environment variables, using this:

| Variable Name | Description | Default |
| :------------ | :---------- | :------ |
| `EXTRA_TF_VARS`           | Comma-separated `key=value` pairs passed as additional `-var` arguments to Terraform (e.g., `containertag=<SHA>,subid=<GUID>`)  This should be used sparingly, only for variables that need to be computed by previous steps. | (none) |

### Infracost (cost estimation)

[Infracost](https://www.infracost.io/) is disabled by default, can be enabled using `enable_infracost: true`, and supplying the INFRACOST_API_KEY via GitHub secrets.

| Secret Name | Description |
| :---------- | :---------- |
| `INFRACOST_API_KEY` | API key for Infracost. Sign up for free at infracost.io to get your API key. |

### Unlock private networking resource firewalls

It is possible to specify a list of resource firewalls to unlock during the pipeline run, however we recommend using self-hosted or managed runners instead of this feature:

| Variable Name | Description | Default |
| :------------ | :---------- | :------ |
| `EXTRA_FIREWALL_UNLOCKS`  | Comma-separated list of additional `storageaccountname` or `keyvaultname` resources whose firewalls should be temporarily opened. | (none) |

Check out the actions [README.md](.github/actions/azure-unlock-firewall/README.md) for more details.

## Use of storage account for Terraform artifacts

Azure Blob Storage is used for state and plan artifacts, to provide stronger RBAC than is available via GitHub packages.

## Using Templates Across Repositories

To use these templates from another **private** repository within the same organization:

1. **Enable Access:** In *this* template repository (`github-azure-iac-templates`), go to `Settings` -> `Actions` -> `General`. Under **Access**, ensure "Accessible from repositories in the `<your_org_name>` organization" is selected.
1. **Update `uses` Path:** In the calling workflow of the *other* repository, update the `uses:` path to the full path of this template repository, **pinning to a specific version tag (recommended)**:

```yaml
  # Replace 'your-org-name' and use a real tag
  uses: your-org-name/github-azure-iac-templates/.github/workflows/terraform-deploy-template.yml@v1.0
```

*(Reference: [Managing access for Actions in an organization](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#managing-access-for-a-private-repository-in-an-organization))*
